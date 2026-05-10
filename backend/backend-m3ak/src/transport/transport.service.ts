import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Inject,
  forwardRef,
  Optional,
  Logger,
} from '@nestjs/common';
import { createHash, randomBytes, timingSafeEqual } from 'crypto';
import { computeTransportFareTnd } from './transport-pricing.util';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { HttpService } from '@nestjs/axios';
import { Connection, Model, Types } from 'mongoose';
import { firstValueFrom } from 'rxjs';
import { TransportRequest, TransportRequestDocument } from './schemas/transport-request.schema';
import { CreateTransportDto } from './dto/create-transport.dto';
import { UserService } from '../user/user.service';
import { MapService } from '../map/map.service';
import { Role } from '../user/enums/role.enum';
import { NotificationService } from '../notification/notification.service';
import { TransportStatut } from './enums/transport-statut.enum';
import { TransportType } from './enums/transport-type.enum';
import { MotifTrajet } from './enums/motif-trajet.enum';
import { CHAUFFEURS_SOLIDAIRES_TYPE } from '../mobilite/mobilite.constants';
import { Vehicle, VehicleDocument } from '../vehicle/schemas/vehicle.schema';
import {
  VehicleReservation,
  VehicleReservationDocument,
} from '../vehicle-reservation/schemas/vehicle-reservation.schema';
import { VehicleStatut } from '../vehicle/enums/vehicle-statut.enum';
import type { Accessibilite } from '../vehicle/schemas/vehicle.schema';
import { TransportGateway } from '../mobilite/transport/transport.gateway';

/** Mapping type handicap → clé accessibilité véhicule (extensible). */
const HANDICAP_ACCESSIBILITE = new Map<string, keyof Accessibilite>([
  ['fauteuil', 'rampeAcces'],
  ['visuel', 'animalAccepte'],
  ['moteur', 'siegePivotant'],
]);

/** Mots-clés besoins d’assistance → contraintes accessibilité (heuristique). */
const NEED_KEYWORDS: Array<{ keys: string[]; check: (a: Accessibilite) => boolean }> = [
  { keys: ['rampe', 'fauteuil', 'roulant', 'wheelchair'], check: (a) => a.rampeAcces === true },
  { keys: ['pivot', 'moteur', 'siege', 'assise'], check: (a) => a.siegePivotant === true },
  { keys: ['chien', 'animal', 'guide', 'visuel'], check: (a) => a.animalAccepte === true },
  { keys: ['coffre', 'equipement', 'volume'], check: (a) => a.coffreVaste === true },
  { keys: ['clim', 'temperature'], check: (a) => a.climatisation === true },
];

const STATUT_LABELS: Record<TransportStatut, string> = {
  [TransportStatut.EN_ATTENTE]: 'En attente d\'un chauffeur',
  [TransportStatut.ACCEPTEE]: 'Chauffeur assigné',
  [TransportStatut.EN_ROUTE]: 'Chauffeur en route',
  [TransportStatut.ARRIVEE]: 'Chauffeur arrivé',
  [TransportStatut.EN_COURS]: 'Trajet en cours',
  [TransportStatut.TERMINEE]: 'Trajet terminé',
  [TransportStatut.ANNULEE]: 'Course annulée',
};

interface ChauffeurMongoLean {
  _id: Types.ObjectId;
  nom?: string;
  prenom?: string;
  noteMoyenne?: number;
  typeAccompagnant?: string | null;
  telephone?: string | null;
  photoProfil?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  disponible?: boolean;
  lastLocationAt?: Date | null;
}

interface AccompagnantPopulated {
  _id: Types.ObjectId;
  nom?: string;
  prenom?: string;
  noteMoyenne?: number;
  typeAccompagnant?: string | null;
  telephone?: string | null;
  photoProfil?: string | null;
  latitude?: number | null;
  longitude?: number | null;
}

@Injectable()
export class TransportService {
  private readonly logger = new Logger(TransportService.name);
  private readonly flaskTransportUrl: string | null;
  private readonly defaultMatchingRadiusKm: number;
  private readonly fareBaseTnd: number;
  private readonly farePerKmTnd: number;
  private readonly farePerMinuteTnd: number;

  constructor(
    @InjectModel(TransportRequest.name) private transportModel: Model<TransportRequestDocument>,
    @InjectModel(Vehicle.name) private vehicleModel: Model<VehicleDocument>,
    @InjectModel(VehicleReservation.name)
    private vehicleReservationModel: Model<VehicleReservationDocument>,
    @InjectConnection() private readonly connection: Connection,
    private userService: UserService,
    private mapService: MapService,
    private httpService: HttpService,
    private configService: ConfigService,
    private notificationService: NotificationService,
    @Optional()
    @Inject(forwardRef(() => TransportGateway))
    private readonly transportGateway?: TransportGateway,
  ) {
    this.flaskTransportUrl = this.configService.get<string>('FLASK_TRANSPORT_URL') ?? null;
    this.defaultMatchingRadiusKm = Number(
      this.configService.get<string>('TRANSPORT_MATCHING_RADIUS_KM') ?? 15,
    );
    this.fareBaseTnd = Number(this.configService.get<string>('TRANSPORT_FARE_BASE_TND') ?? 2.5);
    this.farePerKmTnd = Number(this.configService.get<string>('TRANSPORT_FARE_PER_KM_TND') ?? 0.8);
    this.farePerMinuteTnd = Number(
      this.configService.get<string>('TRANSPORT_FARE_PER_MINUTE_TND') ?? 0.15,
    );
  }

  async create(demandeurId: string, dto: CreateTransportDto) {
    const estimate = await this.estimateTrip(
      dto.latitudeDepart,
      dto.longitudeDepart,
      dto.latitudeArrivee,
      dto.longitudeArrivee,
    );

    return this.transportModel.create({
      demandeurId: new Types.ObjectId(demandeurId),
      accompagnantId: null,
      vehicleId: null,
      typeTransport: dto.typeTransport,
      motifTrajet: dto.motifTrajet ?? null,
      prioriteMedicale: dto.prioriteMedicale === true,
      depart: dto.depart,
      destination: dto.destination,
      latitudeDepart: dto.latitudeDepart,
      longitudeDepart: dto.longitudeDepart,
      latitudeArrivee: dto.latitudeArrivee,
      longitudeArrivee: dto.longitudeArrivee,
      dateHeure: new Date(dto.dateHeure),
      besoinsAssistance: dto.besoinsAssistance ?? [],
      statut: TransportStatut.EN_ATTENTE,
      distanceEstimeeKm: estimate.distanceKm,
      dureeEstimeeMinutes: estimate.durationMinutes,
      prixEstimeTnd: estimate.priceTnd,
    });
  }

  /**
   * Crée une demande transport liée à une réservation véhicule (idempotent via vehicleReservationId).
   * date + heure : composants calendaires en UTC (aligné sur date ISO YYYY-MM-DD du DTO).
   */
  async createLinkedToVehicleReservation(
    reservation: VehicleReservationDocument,
  ): Promise<TransportRequestDocument> {
    const existing = await this.transportModel
      .findOne({ vehicleReservationId: reservation._id })
      .exec();
    if (existing) {
      return existing;
    }

    const veh = await this.vehicleModel.findById(reservation.vehicleId).exec();
    if (!veh) {
      throw new NotFoundException('Véhicule non trouvé');
    }

    const departText = reservation.lieuDepart?.trim() || 'Tunis, Tunisie';
    const destText = reservation.lieuDestination?.trim() || departText;

    const [depCoords, arrCoords] = await Promise.all([
      this.coordsForAddress(reservation.lieuDepart),
      this.coordsForAddress(
        reservation.lieuDestination?.trim() ? reservation.lieuDestination : null,
      ),
    ]);

    const dateVal =
      reservation.date instanceof Date ? reservation.date : new Date(reservation.date);
    const dateHeure = this.combineReservationDateHeureUtc(dateVal, reservation.heure);

    const besoinsAssistance = reservation.besoinsSpecifiques?.trim()
      ? [reservation.besoinsSpecifiques.trim()]
      : [];

    const estimate = await this.estimateTrip(
      depCoords.lat,
      depCoords.lon,
      arrCoords.lat,
      arrCoords.lon,
    );

    return this.transportModel.create({
      demandeurId: reservation.userId,
      accompagnantId: null,
      vehicleId: reservation.vehicleId,
      typeTransport: TransportType.QUOTIDIEN,
      motifTrajet: null,
      prioriteMedicale: false,
      depart: departText,
      destination: destText,
      latitudeDepart: depCoords.lat,
      longitudeDepart: depCoords.lon,
      latitudeArrivee: arrCoords.lat,
      longitudeArrivee: arrCoords.lon,
      dateHeure,
      besoinsAssistance,
      statut: TransportStatut.EN_ATTENTE,
      vehicleReservationId: reservation._id,
      scoreMatching: null,
      dateHeureArrivee: null,
      dureeMinutes: null,
      distanceEstimeeKm: estimate.distanceKm,
      dureeEstimeeMinutes: estimate.durationMinutes,
      prixEstimeTnd: estimate.priceTnd,
      prixFinalTnd: null,
      raisonAnnulation: null,
      annuleParUserId: null,
    });
  }

  /** Annulation du transport suite annulation réservation véhicule (côté métier réservation). */
  async onVehicleReservationCancelled(reservation: VehicleReservationDocument): Promise<void> {
    const tid = reservation.transportId;
    if (!tid) return;
    const t = await this.transportModel.findById(tid).exec();
    if (!t || t.statut === TransportStatut.TERMINEE || t.statut === TransportStatut.ANNULEE) {
      return;
    }
    await this.transportModel
      .findByIdAndUpdate(tid, {
        $set: {
          statut: TransportStatut.ANNULEE,
          raisonAnnulation: 'Réservation véhicule annulée',
          annuleParUserId: reservation.userId,
          shareTokenHash: null,
          shareTokenExpiresAt: null,
        },
      })
      .exec();
    this.transportGateway?.broadcastStatusUpdate(tid.toString(), TransportStatut.ANNULEE);
    try {
      if (t.accompagnantId) {
        await this.notificationService.notifyDriver(
          t.accompagnantId.toString(),
          'Course annulée',
          'La réservation véhicule associée a été annulée.',
          'TRANSPORT_CANCELLED',
          tid.toString(),
        );
      }
    } catch (err: unknown) {
      this.logger.error(err instanceof Error ? err.message : String(err));
    }
  }

  /** Clôture transport si la réservation est passée à TERMINEE hors flux transport (peu fréquent). */
  async onVehicleReservationTerminated(reservation: VehicleReservationDocument): Promise<void> {
    const tid = reservation.transportId;
    if (!tid) return;
    const t = await this.transportModel.findById(tid).exec();
    if (!t || t.statut === TransportStatut.TERMINEE || t.statut === TransportStatut.ANNULEE) {
      return;
    }
    await this.transportModel
      .findByIdAndUpdate(tid, {
        $set: {
          statut: TransportStatut.TERMINEE,
          shareTokenHash: null,
          shareTokenExpiresAt: null,
        },
      })
      .exec();
    this.transportGateway?.broadcastStatusUpdate(tid.toString(), TransportStatut.TERMINEE);
  }

  private combineReservationDateHeureUtc(dateVal: Date, heure: string): Date {
    const y = dateVal.getUTCFullYear();
    const m = dateVal.getUTCMonth();
    const day = dateVal.getUTCDate();
    const parts = heure.split(':');
    const hh = parseInt(parts[0] || '0', 10) || 0;
    const mm = parseInt(parts[1] || '0', 10) || 0;
    return new Date(Date.UTC(y, m, day, hh, mm, 0, 0));
  }

  private async coordsForAddress(label: string | null | undefined): Promise<{
    lat: number;
    lon: number;
  }> {
    const fallback = { lat: 36.8065, lon: 10.1815 };
    if (!label?.trim()) {
      return fallback;
    }
    try {
      const results = await this.mapService.geocode(label.trim(), 'tn', 1);
      if (results.length > 0) {
        return { lat: results[0].lat, lon: results[0].lon };
      }
    } catch {
      /* Nominatim indisponible : repli centre Tunis */
    }
    return fallback;
  }

  /**
   * Étape 1 : Flask si configuré ; sinon matching NestJS avec score, véhicules adaptés, top 10.
   */
  async findMatchingChauffeurs(
    latitudeDepart: number,
    longitudeDepart: number,
    typeHandicap?: string,
    urgence = false,
    rayonKm?: number,
    besoinsAssistance?: string[],
    flaskMeta?: { typeTransport?: TransportType; motifTrajet?: MotifTrajet | null; prioriteMedicale?: boolean },
  ): Promise<unknown> {
    if (!Number.isFinite(latitudeDepart) || !Number.isFinite(longitudeDepart)) {
      throw new BadRequestException('latitude et longitude valides sont requis');
    }
    const effectiveRadiusKm =
      Number.isFinite(rayonKm as number) && (rayonKm as number) > 0
        ? (rayonKm as number)
        : this.defaultMatchingRadiusKm;

    const besoins = besoinsAssistance?.filter((b) => typeof b === 'string' && b.trim()) ?? [];

    if (this.flaskTransportUrl) {
      try {
        const url = `${this.flaskTransportUrl.replace(/\/$/, '')}/api/match`;
        const { data, status } = await firstValueFrom(
          this.httpService.post<unknown>(
            url,
            {
              latitude: latitudeDepart,
              longitude: longitudeDepart,
              typeHandicap,
              urgence,
              rayonKm: effectiveRadiusKm,
              besoinsAssistance: besoins,
              typeTransport: flaskMeta?.typeTransport,
              motifTrajet: flaskMeta?.motifTrajet,
              prioriteMedicale: flaskMeta?.prioriteMedicale,
            },
            { timeout: 8000, validateStatus: () => true },
          ),
        );
        if (status >= 200 && status < 300) {
          // Corps inchangé pour rétrocompatibilité clients existants (Flask peut ignorer les champs POST supplémentaires).
          return data;
        }
      } catch {
        // Repli NestJS natif
      }
    }

    return this.matchingNestJsNatif(
      latitudeDepart,
      longitudeDepart,
      typeHandicap,
      urgence,
      effectiveRadiusKm,
      besoins,
    );
  }

  private async matchingNestJsNatif(
    latitudeDepart: number,
    longitudeDepart: number,
    typeHandicap: string | undefined,
    urgence: boolean,
    rayonKm: number,
    besoinsAssistance: string[],
  ): Promise<{
    source: 'nestjs';
    total: number;
    nestjsContract: string;
    accompagnants: Array<{
      _id: Types.ObjectId;
      nom: string;
      prenom: string;
      noteMoyenne: number;
      typeAccompagnant: string | null;
      telephone: string | null;
      photoProfil: string | null;
      distanceKm: number;
      /** @deprecated alias historique — utiliser scoreMatching */
      score: number;
      scoreMatching: number;
      subscores: {
        proximity: number;
        rating: number;
        handicapVehicleFit: number;
        needsAdequacy: number;
        urgencyRecency: number;
      };
      vehicles: Array<{
        _id: Types.ObjectId;
        marque: string;
        modele: string;
        accessibilite: Accessibilite;
        eligible: boolean;
        needsAdequacy: number;
        handicapFit: boolean;
      }>;
      recommendedVehicle: {
        _id: Types.ObjectId;
        marque: string;
        modele: string;
        accessibilite: Accessibilite;
      } | null;
      vehicle: { marque: string; modele: string; accessibilite: Accessibilite } | null;
    }>;
  }> {
    const coll = this.connection.collection('users');
    const raw = (await coll
      .find({
        role: Role.ACCOMPAGNANT,
        typeAccompagnant: CHAUFFEURS_SOLIDAIRES_TYPE,
        disponible: true,
        latitude: { $exists: true, $ne: null },
        longitude: { $exists: true, $ne: null },
      })
      .toArray()) as unknown as ChauffeurMongoLean[];

    type Row = {
      doc: ChauffeurMongoLean;
      distanceKm: number;
      vehicles: VehicleDocument[];
      vehicleRows: Array<{
        _id: Types.ObjectId;
        marque: string;
        modele: string;
        accessibilite: Accessibilite;
        eligible: boolean;
        needsAdequacy: number;
        handicapFit: boolean;
      }>;
      recommended: VehicleDocument | null;
      handicapVehicleFit: number;
      needsAdequacy: number;
    };

    const inRadius: Row[] = [];
    const thLower = typeHandicap?.trim().toLowerCase();
    const handicapKey = thLower ? HANDICAP_ACCESSIBILITE.get(thLower) : null;
    const strictHandicap = !!(thLower && handicapKey);

    for (const doc of raw) {
      const lat = doc.latitude;
      const lng = doc.longitude;
      if (lat == null || lng == null) continue;
      const distanceKm = this.haversineKm(latitudeDepart, longitudeDepart, lat, lng);
      if (distanceKm > rayonKm) continue;

      const vehicles = await this.vehicleModel
        .find({ ownerId: doc._id, statut: VehicleStatut.VALIDE })
        .exec();

      const vehicleRows = vehicles.map((v) => {
        const acc = v.accessibilite ?? ({} as Accessibilite);
        const handicapFit = !handicapKey ? true : acc[handicapKey] === true;
        const eligible = strictHandicap ? handicapFit : true;
        return {
          _id: v._id as Types.ObjectId,
          marque: v.marque,
          modele: v.modele,
          accessibilite: acc,
          eligible,
          needsAdequacy: this.computeNeedsAdequacy(acc, besoinsAssistance),
          handicapFit,
        };
      });

      const bestVehicleRow =
        vehicleRows
          .filter((r) => r.eligible)
          .sort((a, b) => b.needsAdequacy - a.needsAdequacy)[0] ?? null;
      const recDoc = bestVehicleRow
        ? vehicles.find((x) => x._id.toString() === bestVehicleRow._id.toString()) ?? null
        : null;

      if (strictHandicap && !recDoc) {
        continue;
      }

      const bestNeeds = vehicleRows.length
        ? Math.max(...vehicleRows.map((r) => r.needsAdequacy))
        : besoinsAssistance.length
          ? 0
          : 1;
      const handicapVehicleFit = strictHandicap ? (recDoc ? 1 : 0) : recDoc ? 1 : 0.5;

      inRadius.push({
        doc,
        distanceKm,
        vehicles,
        vehicleRows,
        recommended: recDoc,
        handicapVehicleFit,
        needsAdequacy: bestNeeds,
      });
    }

    const dixMinutesMs = 10 * 60 * 1000;
    const seuilRecent = Date.now() - dixMinutesMs;

    const proxRawList = inRadius.map((r) => 1 / (r.distanceKm + 0.1));
    const maxProx = Math.max(...proxRawList, 1e-6);

    const scored = inRadius.map((row, idx) => {
      const { doc, distanceKm, vehicleRows, recommended } = row;
      const note = doc.noteMoyenne ?? 0;
      const disponible = doc.disponible === true;
      const lastAt = doc.lastLocationAt ? new Date(doc.lastLocationAt).getTime() : 0;
      const recentUrgence = urgence && lastAt >= seuilRecent;
      const proxRaw = proxRawList[idx] ?? 1 / (distanceKm + 0.1);
      const sub = {
        proximity: Math.min(1, proxRaw / maxProx),
        rating: note / 5,
        handicapVehicleFit: row.handicapVehicleFit,
        needsAdequacy: row.needsAdequacy,
        urgencyRecency: recentUrgence ? 1 : 0,
      };
      const score =
        sub.proximity * 0.45 +
        sub.rating * 0.25 +
        sub.handicapVehicleFit * 0.15 +
        sub.needsAdequacy * 0.15 +
        (urgence && disponible ? 0.05 : 0) +
        (recentUrgence ? 0.05 : 0);
      const rounded = Math.round(score * 1000) / 1000;

      return {
        doc,
        distanceKm: Math.round(distanceKm * 10) / 10,
        score: rounded,
        vehicleRows,
        recommended,
        subscores: sub,
        recentUrgence,
      };
    });

    scored.sort((a, b) => {
      if (urgence && a.recentUrgence !== b.recentUrgence) {
        return a.recentUrgence ? -1 : 1;
      }
      return b.score - a.score;
    });

    const top = scored.slice(0, 10).map((s) => {
      const rec = s.recommended;
      const legacyVehicle = rec
        ? { marque: rec.marque, modele: rec.modele, accessibilite: rec.accessibilite ?? {} }
        : null;
      const recommendedVehicle = rec
        ? {
            _id: rec._id as Types.ObjectId,
            marque: rec.marque,
            modele: rec.modele,
            accessibilite: rec.accessibilite ?? ({} as Accessibilite),
          }
        : null;
      return {
        _id: s.doc._id,
        nom: s.doc.nom ?? '',
        prenom: s.doc.prenom ?? '',
        noteMoyenne: s.doc.noteMoyenne ?? 0,
        typeAccompagnant: s.doc.typeAccompagnant ?? null,
        telephone: s.doc.telephone ?? null,
        photoProfil: s.doc.photoProfil ?? null,
        distanceKm: s.distanceKm,
        score: s.score,
        scoreMatching: s.score,
        subscores: s.subscores,
        vehicles: s.vehicleRows,
        recommendedVehicle,
        vehicle: legacyVehicle,
      };
    });

    return {
      source: 'nestjs',
      total: top.length,
      nestjsContract:
        'Chaque candidat inclut score (=scoreMatching), subscores, vehicles (tous les véhicules VALIDE du chauffeur avec flags), recommendedVehicle.',
      accompagnants: top,
    };
  }

  private computeNeedsAdequacy(accessibilite: Accessibilite, besoins: string[]): number {
    if (!besoins.length) return 1;
    let matched = 0;
    for (const needRaw of besoins) {
      const need = needRaw.toLowerCase();
      const rule = NEED_KEYWORDS.find((r) => r.keys.some((k) => need.includes(k)));
      if (!rule) {
        matched += 0.5;
        continue;
      }
      if (rule.check(accessibilite)) matched += 1;
    }
    return Math.round((matched / besoins.length) * 1000) / 1000;
  }

  /** Véhicule VALIDE adapté au handicap si besoin ; sinon premier VALIDE si type inconnu / absent. */
  private async resolveVehicleForMatching(
    ownerId: Types.ObjectId,
    typeHandicap?: string,
  ): Promise<VehicleDocument | null> {
    const vehicles = await this.vehicleModel
      .find({ ownerId, statut: VehicleStatut.VALIDE })
      .exec();
    if (vehicles.length === 0) return null;

    const th = typeHandicap?.trim().toLowerCase();
    if (!th) return vehicles[0];

    const key = HANDICAP_ACCESSIBILITE.get(th);
    if (!key) return vehicles[0];

    for (const v of vehicles) {
      if (v.accessibilite?.[key] === true) return v;
    }
    return null;
  }

  private haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLng = ((lng2 - lng1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLng / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  async accept(
    transportId: string,
    accompagnantId: string,
    options?: {
      scoreMatching?: number;
      vehicleId?: string;
      matchingSubscores?: {
        proximity: number;
        rating: number;
        handicapVehicleFit: number;
        needsAdequacy: number;
        urgencyRecency?: number;
      };
    },
  ) {
    const scoreMatching = options?.scoreMatching;
    const vehicleId = options?.vehicleId;
    const matchingSubscores = options?.matchingSubscores;
    const accompagnant = await this.userService.findByIdWithPassword(accompagnantId);
    if (!accompagnant) throw new NotFoundException('Accompagnant non trouvé');
    if (accompagnant.role !== Role.ACCOMPAGNANT) {
      throw new ForbiddenException('Seul un accompagnant peut accepter une demande');
    }
    if (accompagnant.typeAccompagnant !== CHAUFFEURS_SOLIDAIRES_TYPE) {
      throw new ForbiddenException(
        'Seuls les accompagnants « Chauffeurs solidaires » peuvent accepter une demande',
      );
    }
    if (!accompagnant.disponible) {
      throw new BadRequestException('Accompagnant non disponible');
    }

    const pending = await this.transportModel.findById(transportId).exec();
    if (!pending) throw new NotFoundException('Demande de transport non trouvée');
    if (pending.statut !== TransportStatut.EN_ATTENTE) {
      throw new BadRequestException('Cette demande n\'est plus disponible');
    }

    if (pending.vehicleId) {
      const bookedVehicle = await this.vehicleModel.findById(pending.vehicleId).exec();
      if (!bookedVehicle) {
        throw new NotFoundException('Véhicule associé à la demande introuvable');
      }
      if (bookedVehicle.ownerId.toString() !== accompagnantId) {
        throw new ForbiddenException(
          'Seul le propriétaire du véhicule réservé peut accepter cette demande',
        );
      }
    }
    if (
      vehicleId &&
      pending.vehicleId &&
      pending.vehicleId.toString() !== vehicleId
    ) {
      throw new BadRequestException('Le véhicule ne correspond pas à la réservation liée');
    }

    const update: Record<string, unknown> = {
      accompagnantId: new Types.ObjectId(accompagnantId),
      statut: TransportStatut.ACCEPTEE,
      scoreMatching: scoreMatching ?? null,
    };
    if (matchingSubscores) {
      update.matchingSubscores = matchingSubscores;
    }
    if (vehicleId) {
      update.vehicleId = new Types.ObjectId(vehicleId);
    } else if (pending.vehicleId) {
      update.vehicleId = pending.vehicleId;
    }

    const accepted = await this.transportModel
      .findOneAndUpdate(
        { _id: new Types.ObjectId(transportId), statut: TransportStatut.EN_ATTENTE },
        { $set: update },
        { new: true },
      )
      .populate('demandeurId accompagnantId vehicleId', '-password')
      .exec();

    if (!accepted) {
      const exists = await this.transportModel.findById(transportId).exec();
      if (!exists) throw new NotFoundException('Demande de transport non trouvée');
      throw new BadRequestException('Cette demande n\'est plus disponible');
    }

    const demandeur = accepted.demandeurId as { _id?: Types.ObjectId; prenom?: string };
    const demandeurIdStr = demandeur?._id?.toString();
    const rideIdStr = accepted._id.toString();

    const fcmTokenChauffeur = await this.notificationService.getFcmTokenForUser(accompagnantId);
    if (fcmTokenChauffeur) {
      try {
        await this.notificationService.sendPushToDriver(fcmTokenChauffeur, {
          _id: rideIdStr,
          depart: accepted.depart,
          destination: accepted.destination,
          distanceEstimeeKm: accepted.distanceEstimeeKm ?? 0,
          besoinsAssistance: accepted.besoinsAssistance ?? [],
          typeTransport: accepted.typeTransport,
        });
      } catch (err: unknown) {
        this.logger.error(err instanceof Error ? err.message : String(err));
      }
    }

    if (demandeurIdStr) {
      try {
        await this.notificationService.notifyPassager(
          demandeurIdStr,
          'Course acceptée',
          'Un chauffeur solidaire a accepté votre demande de transport.',
          'TRANSPORT_ACCEPTED',
          rideIdStr,
        );
      } catch (err: unknown) {
        this.logger.error(err instanceof Error ? err.message : String(err));
      }
    }

    this.transportGateway?.broadcastStatusUpdate(rideIdStr, TransportStatut.ACCEPTEE);

    if (accepted.vehicleReservationId) {
      await this.vehicleReservationModel
        .updateOne(
          { _id: accepted.vehicleReservationId, statut: 'EN_ATTENTE' },
          { $set: { statut: 'CONFIRMEE' } },
        )
        .exec();
    }

    return accepted;
  }

  async terminate(
    transportId: string,
    userId: string,
    dureeMinutes?: number,
    dateHeureArrivee?: string,
  ) {
    const transport = await this.transportModel.findById(transportId).exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');
    if (
      transport.statut !== TransportStatut.ACCEPTEE &&
      transport.statut !== TransportStatut.EN_ROUTE &&
      transport.statut !== TransportStatut.ARRIVEE &&
      transport.statut !== TransportStatut.EN_COURS
    ) {
      throw new BadRequestException('Ce transport ne peut pas être marqué comme terminé');
    }
    const isAccompagnant = transport.accompagnantId?.toString() === userId;
    const isDemandeur = transport.demandeurId.toString() === userId;
    if (!isAccompagnant && !isDemandeur) {
      throw new ForbiddenException('Vous ne pouvez pas terminer cette demande');
    }
    const update: Record<string, unknown> = { statut: TransportStatut.TERMINEE };
    if (dureeMinutes != null) {
      update.dureeMinutes = dureeMinutes;
    }
    if (dateHeureArrivee) {
      const arrived = new Date(dateHeureArrivee);
      update.dateHeureArrivee = arrived;
      if (dureeMinutes == null) {
        const dep = transport.dateHeure.getTime();
        update.dureeMinutes = Math.round((arrived.getTime() - dep) / 60000);
      }
    }

    const durationForPrice =
      (update.dureeMinutes as number | undefined) ?? transport.dureeEstimeeMinutes ?? 0;
    const distanceForPrice = transport.distanceEstimeeKm ?? 0;
    update.prixFinalTnd = this.calculateFareTnd(distanceForPrice, durationForPrice);

    const done = await this.transportModel
      .findByIdAndUpdate(transportId, { $set: update }, { new: true })
      .populate('demandeurId accompagnantId vehicleId', '-password')
      .exec();

    try {
      await this.notificationService.notifyPassager(
        transport.demandeurId.toString(),
        'Trajet terminé',
        'Votre course est terminée. Vous pouvez laisser un avis.',
        'TRANSPORT_COMPLETED',
        transportId,
      );
    } catch (err: unknown) {
      this.logger.error(err instanceof Error ? err.message : String(err));
    }

    this.transportGateway?.broadcastStatusUpdate(transportId, TransportStatut.TERMINEE);

    await this.clearShareTokens(transportId);

    if (transport.vehicleReservationId) {
      const duree =
        (update.dureeMinutes as number | undefined) ?? transport.dureeMinutes ?? null;
      await this.vehicleReservationModel
        .updateOne(
          { _id: transport.vehicleReservationId },
          {
            $set: {
              statut: 'TERMINEE',
              dateHeureFin: new Date(),
              dureeTrajet: duree,
            },
          },
        )
        .exec();
    }

    return done;
  }

  async cancel(transportId: string, userId: string, raison?: string) {
    const transport = await this.transportModel.findById(transportId).exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');

    const isDemandeur = transport.demandeurId.toString() === userId;
    const isAccompagnant = transport.accompagnantId?.toString() === userId;
    if (!isDemandeur && !isAccompagnant) {
      throw new ForbiddenException('Vous ne pouvez pas annuler cette demande');
    }
    if (
      transport.statut === TransportStatut.TERMINEE ||
      transport.statut === TransportStatut.ANNULEE
    ) {
      throw new BadRequestException('Ce transport est déjà finalisé');
    }

    const canceled = await this.transportModel
      .findByIdAndUpdate(
        transportId,
        {
          $set: {
            statut: TransportStatut.ANNULEE,
            raisonAnnulation: raison ?? null,
            annuleParUserId: new Types.ObjectId(userId),
          },
        },
        { new: true },
      )
      .exec();

    const msgSuffix = raison ? ` (${raison})` : '';
    try {
      if (isDemandeur && transport.accompagnantId) {
        await this.notificationService.notifyDriver(
          transport.accompagnantId.toString(),
          'Course annulée',
          `Le passager a annulé la course${msgSuffix}.`,
          'TRANSPORT_CANCELLED',
          transportId,
        );
      } else if (isAccompagnant) {
        await this.notificationService.notifyPassager(
          transport.demandeurId.toString(),
          'Course annulée',
          `Le chauffeur a annulé la course${msgSuffix}.`,
          'TRANSPORT_CANCELLED',
          transportId,
        );
      }
    } catch (err: unknown) {
      this.logger.error(err instanceof Error ? err.message : String(err));
    }

    this.transportGateway?.broadcastStatusUpdate(transportId, TransportStatut.ANNULEE);

    await this.clearShareTokens(transportId);

    if (transport.vehicleReservationId) {
      await this.vehicleReservationModel
        .updateOne(
          {
            _id: transport.vehicleReservationId,
            statut: { $nin: ['ANNULEE', 'TERMINEE'] },
          },
          { $set: { statut: 'ANNULEE' } },
        )
        .exec();
    }

    return canceled;
  }

  async findByDemandeur(demandeurId: string) {
    return this.transportModel
      .find({ demandeurId: new Types.ObjectId(demandeurId) })
      .populate('accompagnantId', '-password')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findByAccompagnant(accompagnantId: string) {
    return this.transportModel
      .find({ accompagnantId: new Types.ObjectId(accompagnantId) })
      .populate('demandeurId', '-password')
      .sort({ createdAt: -1 })
      .exec();
  }

  /**
   * Demandes ouvertes (sans véhicule pré-assigné) OU réservation véhicule ciblant un des véhicules du chauffeur.
   */
  async findAvailable(chauffeurUserId: string) {
    const myVehicleIds = await this.vehicleModel
      .find({ ownerId: new Types.ObjectId(chauffeurUserId) })
      .select('_id')
      .lean()
      .exec()
      .then((rows) => rows.map((r) => r._id));

    const filter: Record<string, unknown> = {
      statut: TransportStatut.EN_ATTENTE,
      $or: [{ vehicleId: null }, { vehicleId: { $in: myVehicleIds } }],
    };

    const list = await this.transportModel
      .find(filter)
      .populate('demandeurId', '-password')
      .sort({ dateHeure: 1 })
      .exec();
    return list.sort((a, b) => {
      const ra = this.availableSortRank(a);
      const rb = this.availableSortRank(b);
      if (ra !== rb) return ra - rb;
      return a.dateHeure.getTime() - b.dateHeure.getTime();
    });
  }

  /** Tri file chauffeur : priorité médicale > URGENCE > autres, puis `dateHeure`. */
  private availableSortRank(t: TransportRequestDocument): number {
    if (t.prioriteMedicale === true) return 0;
    if (t.typeTransport === TransportType.URGENCE) return 1;
    return 2;
  }

  private async clearShareTokens(transportId: string): Promise<void> {
    await this.transportModel
      .updateOne(
        { _id: new Types.ObjectId(transportId) },
        { $set: { shareTokenHash: null, shareTokenExpiresAt: null } },
      )
      .exec();
  }

  private hashShareToken(plain: string): string {
    return createHash('sha256').update(plain, 'utf8').digest('hex');
  }

  async verifyShareToken(rideId: string, plainToken: string): Promise<boolean> {
    if (!plainToken?.trim() || !Types.ObjectId.isValid(rideId)) return false;
    const ride = await this.transportModel
      .findById(rideId)
      .select('shareTokenHash shareTokenExpiresAt statut')
      .lean()
      .exec();
    if (!ride || !ride.shareTokenHash) return false;
    if (ride.shareTokenExpiresAt && new Date(ride.shareTokenExpiresAt as Date) < new Date()) {
      return false;
    }
    if (ride.statut === TransportStatut.TERMINEE || ride.statut === TransportStatut.ANNULEE) {
      return false;
    }
    const h = this.hashShareToken(plainToken.trim());
    const a = Buffer.from(h, 'hex');
    const b = Buffer.from(ride.shareTokenHash as string, 'hex');
    if (a.length !== b.length) return false;
    return timingSafeEqual(a, b);
  }

  /**
   * Crée ou remplace un jeton opaque (une seule valeur affichée au client ; seul le hash est stocké).
   * Réservé au demandeur ou au chauffeur assigné, course acceptée ou en cours.
   */
  async issueShareToken(transportId: string, userId: string): Promise<{ token: string; expiresAt: string }> {
    const t = await this.transportModel.findById(transportId).exec();
    if (!t) throw new NotFoundException('Demande de transport non trouvée');
    const isDemandeur = t.demandeurId.toString() === userId;
    const isChauffeur = t.accompagnantId?.toString() === userId;
    if (!isDemandeur && !isChauffeur) {
      throw new ForbiddenException('Seul le demandeur ou le chauffeur peut partager le trajet');
    }
    const allowedStatuts = [
      TransportStatut.ACCEPTEE,
      TransportStatut.EN_ROUTE,
      TransportStatut.ARRIVEE,
      TransportStatut.EN_COURS,
    ];
    if (!allowedStatuts.includes(t.statut)) {
      throw new BadRequestException(
        'Partage disponible une fois la course acceptée (jusqu’à la fin du trajet)',
      );
    }
    const plain = randomBytes(32).toString('base64url');
    const hash = this.hashShareToken(plain);
    const marginMs = 2 * 60 * 60 * 1000;
    const estMs = (t.dureeEstimeeMinutes ?? 90) * 60 * 1000;
    const expiresAt = new Date(
      Math.max(Date.now() + 30 * 60 * 1000, t.dateHeure.getTime() + estMs + marginMs),
    );
    await this.transportModel
      .updateOne(
        { _id: t._id },
        { $set: { shareTokenHash: hash, shareTokenExpiresAt: expiresAt } },
      )
      .exec();
    this.logger.log(`Jeton de partage émis pour transport ${transportId} par user ${userId}`);
    return { token: plain, expiresAt: expiresAt.toISOString() };
  }

  async revokeShareToken(transportId: string, userId: string): Promise<void> {
    const t = await this.transportModel.findById(transportId).exec();
    if (!t) throw new NotFoundException('Demande de transport non trouvée');
    const isDemandeur = t.demandeurId.toString() === userId;
    const isChauffeur = t.accompagnantId?.toString() === userId;
    if (!isDemandeur && !isChauffeur) {
      throw new ForbiddenException('Seul le demandeur ou le chauffeur peut révoquer le partage');
    }
    await this.clearShareTokens(transportId);
    this.logger.log(`Jeton de partage révoqué pour transport ${transportId}`);
  }

  async getEtaPublic(transportId: string, plainToken: string) {
    const ok = await this.verifyShareToken(transportId, plainToken);
    if (!ok) throw new ForbiddenException('Lien de suivi invalide ou expiré');
    this.logger.log(`ETA invité transport=${transportId}`);
    return this.getEta(transportId);
  }

  async getSuiviPublic(transportId: string, plainToken: string) {
    const ok = await this.verifyShareToken(transportId, plainToken);
    if (!ok) throw new ForbiddenException('Lien de suivi invalide ou expiré');
    this.logger.log(`Suivi invité transport=${transportId}`);
    const full = await this.getSuivi(transportId);
    return this.sanitizeSuiviForGuest(full);
  }

  private sanitizeSuiviForGuest(full: {
    transport: TransportRequestDocument;
    positionChauffeur: { lat: number | null; lng: number | null; updatedAt?: Date };
    driver: AccompagnantPopulated | null;
    statutLabel: string;
    eta: unknown;
    itineraire: unknown;
    cible: string | null;
  }) {
    const t = full.transport as TransportRequestDocument & {
      demandeurId?: unknown;
    };
    const guestTransport = {
      _id: t._id,
      depart: t.depart,
      destination: t.destination,
      latitudeDepart: t.latitudeDepart,
      longitudeDepart: t.longitudeDepart,
      latitudeArrivee: t.latitudeArrivee,
      longitudeArrivee: t.longitudeArrivee,
      statut: t.statut,
      typeTransport: t.typeTransport,
      motifTrajet: t.motifTrajet ?? null,
      prioriteMedicale: t.prioriteMedicale ?? false,
      dateHeure: t.dateHeure,
      vehicleReservationId: t.vehicleReservationId ?? null,
    };
    const d = full.driver;
    const driverGuest = d
      ? {
          prenom: d.prenom ?? '',
          nom: d.nom ? `${String(d.nom)[0]}.` : '',
          photoProfil: d.photoProfil ?? null,
          noteMoyenne: d.noteMoyenne ?? 0,
        }
      : null;
    return {
      transport: guestTransport,
      positionChauffeur: full.positionChauffeur,
      driver: driverGuest,
      statutLabel: full.statutLabel,
      eta: full.eta,
      itineraire: full.itineraire,
      cible: full.cible,
    };
  }

  async findMatchingCandidatesForTransport(
    transportId: string,
    userId: string,
    typeHandicapOverride?: string,
  ): Promise<unknown> {
    const t = await this.transportModel.findById(transportId).exec();
    if (!t) throw new NotFoundException('Demande de transport non trouvée');
    const isDemandeur = t.demandeurId.toString() === userId;
    if (!isDemandeur) {
      if (t.statut !== TransportStatut.EN_ATTENTE) {
        throw new ForbiddenException('Accès réservé au demandeur pour ce transport');
      }
      const u = await this.userService.findByIdWithPassword(userId);
      if (!u || u.role !== Role.ACCOMPAGNANT || u.typeAccompagnant !== CHAUFFEURS_SOLIDAIRES_TYPE) {
        throw new ForbiddenException('Seul un chauffeur solidaire peut consulter le matching d’une course ouverte');
      }
    }
    const th = typeHandicapOverride?.trim();
    const urgence = t.typeTransport === TransportType.URGENCE;
    return this.findMatchingChauffeurs(
      t.latitudeDepart,
      t.longitudeDepart,
      th,
      urgence,
      undefined,
      t.besoinsAssistance ?? [],
      {
        typeTransport: t.typeTransport,
        motifTrajet: t.motifTrajet ?? undefined,
        prioriteMedicale: t.prioriteMedicale === true,
      },
    );
  }

  async findUnifiedHistory(userId: string, page = 1, limit = 20) {
    const oid = new Types.ObjectId(userId);
    const safeLimit = Math.min(100, Math.max(1, limit));
    const safePage = Math.max(1, page);
    const window = Math.min(500, safePage * safeLimit + safeLimit * 2);
    const [transports, reservations] = await Promise.all([
      this.transportModel
        .find({ $or: [{ demandeurId: oid }, { accompagnantId: oid }] })
        .populate('accompagnantId vehicleId', '-password')
        .sort({ updatedAt: -1 })
        .limit(window)
        .lean()
        .exec(),
      this.vehicleReservationModel
        .find({ userId: oid })
        .populate('vehicleId', '-password')
        .sort({ updatedAt: -1 })
        .limit(window)
        .lean()
        .exec(),
    ]);

    const tItems = transports.map((tr) => ({
      source: 'TRANSPORT' as const,
      sortAt: new Date(
        (tr as { updatedAt?: Date }).updatedAt ?? tr.dateHeure,
      ).getTime(),
      item: {
        source: 'TRANSPORT' as const,
        id: String(tr._id),
        statut: tr.statut,
        typeTransport: tr.typeTransport,
        motifTrajet: tr.motifTrajet ?? null,
        prioriteMedicale: tr.prioriteMedicale ?? false,
        dateHeure: tr.dateHeure,
        depart: tr.depart,
        destination: tr.destination,
        dureeMinutes: tr.dureeMinutes ?? null,
        prixFinalTnd: tr.prixFinalTnd ?? null,
        accompagnant: tr.accompagnantId ?? null,
        vehicle: tr.vehicleId ?? null,
      },
    }));
    const rItems = reservations.map((r) => ({
      source: 'VEHICLE_RESERVATION' as const,
      sortAt: new Date((r as { updatedAt?: Date }).updatedAt ?? r.date).getTime(),
      item: {
        source: 'VEHICLE_RESERVATION' as const,
        id: String(r._id),
        statut: r.statut,
        date: r.date,
        heure: r.heure,
        lieuDepart: r.lieuDepart,
        lieuDestination: r.lieuDestination,
        transportId: r.transportId ? String(r.transportId) : null,
        vehicle: r.vehicleId ?? null,
        dureeTrajet: r.dureeTrajet ?? null,
      },
    }));
    const merged = [...tItems, ...rItems].sort((a, b) => b.sortAt - a.sortAt);
    const skip = (safePage - 1) * safeLimit;
    const slice = merged.slice(skip, skip + safeLimit);
    return {
      page: safePage,
      limit: safeLimit,
      items: slice.map((x) => x.item),
      totalReturned: merged.length,
      note:
        'Fusion des `transport` et `vehicle-reservations` de l’utilisateur sur une fenêtre récente (tri par updatedAt). Pour une pagination exhaustive, agréger côté client ou étendre avec agrégation Mongo.',
    };
  }

  async findById(transportId: string) {
    const transport = await this.transportModel
      .findById(transportId)
      .populate('demandeurId accompagnantId vehicleId', '-password')
      .exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');
    return transport;
  }

  /** Course brute pour le gateway (pas d’exception si introuvable). */
  async findTransportDocumentById(transportId: string): Promise<TransportRequestDocument | null> {
    if (!Types.ObjectId.isValid(transportId)) return null;
    return this.transportModel.findById(transportId).exec();
  }

  /** Mise à jour atomique de la position chauffeur (WebSocket). */
  async updateDriverLocation(rideId: string, lat: number, lng: number): Promise<void> {
    await this.transportModel
      .updateOne(
        { _id: new Types.ObjectId(rideId) },
        { $set: { driverCurrentLat: lat, driverCurrentLng: lng } },
      )
      .exec();
  }

  async getEta(transportId: string) {
    const transport = await this.transportModel.findById(transportId).exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');
    if (
      transport.statut !== TransportStatut.ACCEPTEE &&
      transport.statut !== TransportStatut.EN_ROUTE &&
      transport.statut !== TransportStatut.ARRIVEE &&
      transport.statut !== TransportStatut.EN_COURS
    ) {
      throw new BadRequestException('ETA disponible uniquement pour un transport actif');
    }
    const accompagnantId = transport.accompagnantId?.toString();
    if (!accompagnantId) throw new BadRequestException('Aucun accompagnant assigné');
    const accompagnant = await this.userService.findByIdWithPassword(accompagnantId);
    if (!accompagnant) throw new NotFoundException('Accompagnant non trouvé');

    const latC =
      transport.driverCurrentLat ?? accompagnant.latitude ?? transport.latitudeDepart;
    const lonC =
      transport.driverCurrentLng ?? accompagnant.longitude ?? transport.longitudeDepart;
    const latU = transport.latitudeDepart;
    const lonU = transport.longitudeDepart;

    if (this.flaskTransportUrl) {
      try {
        const { data } = await firstValueFrom(
          this.httpService.get<{
            distance_km: number;
            duree_minutes: number;
            vitesse_kmh_utilisee: number;
          }>(`${this.flaskTransportUrl.replace(/\/$/, '')}/api/eta`, {
            params: {
              lat_chauffeur: latC,
              lon_chauffeur: lonC,
              lat_utilisateur: latU,
              lon_utilisateur: lonU,
            },
            timeout: 5000,
          }),
        );
        return data;
      } catch {
        // Repli Haversine
      }
    }
    const distance_km = this.haversineKm(latC, lonC, latU, lonU);
    const duree_minutes = this.estimateEtaMinutesByDistance(distance_km);
    return {
      distance_km: Math.round(distance_km * 100) / 100,
      duree_minutes: Math.round(duree_minutes * 10) / 10,
      vitesse_kmh_utilisee: 30,
    };
  }

  async getSuivi(transportId: string) {
    const transport = await this.transportModel
      .findById(transportId)
      .populate('demandeurId accompagnantId vehicleId', '-password')
      .exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');

    const statutLabel = STATUT_LABELS[transport.statut];
    const transportAvecTimestamps = transport as TransportRequestDocument & { updatedAt?: Date };
    const positionChauffeur = {
      lat: transport.driverCurrentLat ?? null,
      lng: transport.driverCurrentLng ?? null,
      updatedAt: transportAvecTimestamps.updatedAt ?? transportAvecTimestamps.createdAt ?? new Date(),
    };

    const accRaw = transport.accompagnantId as AccompagnantPopulated | null;
    const driver =
      accRaw && accRaw._id
        ? {
            _id: accRaw._id,
            nom: accRaw.nom ?? '',
            prenom: accRaw.prenom ?? '',
            noteMoyenne: accRaw.noteMoyenne ?? 0,
            typeAccompagnant: accRaw.typeAccompagnant ?? null,
            telephone: accRaw.telephone ?? null,
            photoProfil: accRaw.photoProfil ?? null,
          }
        : null;

    const inactive =
      transport.statut === TransportStatut.TERMINEE ||
      transport.statut === TransportStatut.ANNULEE;

    if (inactive) {
      return {
        transport,
        positionChauffeur,
        driver,
        statutLabel,
        eta: null,
        itineraire: null,
        cible: null,
      };
    }

    if (
      transport.statut !== TransportStatut.ACCEPTEE &&
      transport.statut !== TransportStatut.EN_ROUTE &&
      transport.statut !== TransportStatut.ARRIVEE &&
      transport.statut !== TransportStatut.EN_COURS
    ) {
      throw new BadRequestException('Suivi disponible uniquement pour un transport actif');
    }

    const accompagnantId = transport.accompagnantId?.toString();
    if (!accompagnantId) throw new BadRequestException('Aucun accompagnant assigné');
    const accompagnant = await this.userService.findByIdWithPassword(accompagnantId);
    if (!accompagnant) throw new NotFoundException('Accompagnant non trouvé');

    const latNav =
      transport.driverCurrentLat ?? accompagnant.latitude ?? transport.latitudeDepart;
    const lngNav =
      transport.driverCurrentLng ?? accompagnant.longitude ?? transport.longitudeDepart;
    const positionPourItineraire = { lat: latNav, lon: lngNav };

    const pointDepart = { lat: transport.latitudeDepart, lon: transport.longitudeDepart };
    const pointDestination = { lat: transport.latitudeArrivee, lon: transport.longitudeArrivee };
    const pointCible =
      transport.statut === TransportStatut.EN_COURS ? pointDestination : pointDepart;

    const eta = await this.getEta(transportId);
    let itineraire: { distance: number; duration: number; geometry?: unknown } | null = null;
    try {
      itineraire = await this.mapService.getRoute(positionPourItineraire, pointCible);
    } catch {
      // OSRM peut échouer
    }

    return {
      transport,
      positionChauffeur,
      driver,
      statutLabel,
      eta,
      itineraire,
      cible: transport.statut === TransportStatut.EN_COURS ? 'DESTINATION' : 'POINT_DEPART',
    };
  }

  async getPriceEstimate(transportId: string) {
    const transport = await this.transportModel.findById(transportId).exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');

    const dist = transport.distanceEstimeeKm;
    const dur = transport.dureeEstimeeMinutes;
    const prix = transport.prixEstimeTnd;
    if (dist != null && dist > 0 && dur != null && prix != null) {
      return {
        distanceKm: dist,
        durationMin: dur,
        prixEstimeTnd: prix,
        source: 'cache' as const,
      };
    }

    const osrmBase =
      this.configService.get<string>('OSRM_URL') ?? 'https://router.project-osrm.org';
    const baseUrl = osrmBase.replace(/\/$/, '');
    const coords = `${transport.longitudeDepart},${transport.latitudeDepart};${transport.longitudeArrivee},${transport.latitudeArrivee}`;
    let distanceKm = 0;
    let durationMin = 0;
    let source: 'osrm' | 'haversine' = 'haversine';

    try {
      const { data } = await firstValueFrom(
        this.httpService.get<{
          code: string;
          routes?: Array<{ distance: number; duration: number }>;
        }>(`${baseUrl}/route/v1/driving/${coords}`, {
          params: { overview: 'false' },
          timeout: 15000,
        }),
      );
      if (data.code === 'Ok' && data.routes?.[0]) {
        distanceKm = Math.round((data.routes[0].distance / 1000) * 100) / 100;
        durationMin = Math.round((data.routes[0].duration / 60) * 100) / 100;
        source = 'osrm';
      } else {
        throw new Error('OSRM pas Ok');
      }
    } catch {
      distanceKm = Math.round(
        this.haversineKm(
          transport.latitudeDepart,
          transport.longitudeDepart,
          transport.latitudeArrivee,
          transport.longitudeArrivee,
        ) * 100,
      ) / 100;
      durationMin = Math.round(this.estimateEtaMinutesByDistance(distanceKm) * 100) / 100;
      source = 'haversine';
    }

    const baseFare = this.configService.get<number>('TRANSPORT_FARE_BASE_TND', 2.5);
    const perKm = this.configService.get<number>('TRANSPORT_FARE_PER_KM_TND', 0.8);
    const perMin = this.configService.get<number>('TRANSPORT_FARE_PER_MINUTE_TND', 0.15);
    const prixCalc = +(baseFare + distanceKm * perKm + durationMin * perMin).toFixed(2);

    await this.transportModel
      .updateOne(
        { _id: transport._id },
        {
          $set: {
            distanceEstimeeKm: distanceKm,
            dureeEstimeeMinutes: durationMin,
            prixEstimeTnd: prixCalc,
          },
        },
      )
      .exec();

    return {
      distanceKm,
      durationMin,
      prixEstimeTnd: prixCalc,
      source,
    };
  }

  async updateStatut(transportId: string, accompagnantId: string, newStatut: TransportStatut) {
    const transport = await this.transportModel.findById(transportId).exec();
    if (!transport) throw new NotFoundException('Demande de transport non trouvée');
    if (transport.accompagnantId?.toString() !== accompagnantId) {
      throw new ForbiddenException('Seul l\'accompagnant assigné peut mettre à jour ce statut');
    }
    if (newStatut === TransportStatut.ANNULEE) {
      return this.cancel(transportId, accompagnantId, 'Annulée par accompagnant');
    }
    if (newStatut === TransportStatut.TERMINEE) {
      return this.terminate(transportId, accompagnantId);
    }
    this.assertValidTransition(transport.statut, newStatut);

    const updated = await this.transportModel
      .findByIdAndUpdate(transportId, { $set: { statut: newStatut } }, { new: true })
      .populate('demandeurId accompagnantId vehicleId', '-password')
      .exec();

    const { title, body } = this.statusNotificationCopy(newStatut);
    try {
      await this.notificationService.notifyPassager(
        transport.demandeurId.toString(),
        title,
        body,
        'TRANSPORT_STATUS',
        transportId,
      );
    } catch (err: unknown) {
      this.logger.error(err instanceof Error ? err.message : String(err));
    }

    this.transportGateway?.broadcastStatusUpdate(transportId, newStatut);

    return updated;
  }

  private statusNotificationCopy(statut: TransportStatut): { title: string; body: string } {
    switch (statut) {
      case TransportStatut.EN_ROUTE:
        return {
          title: 'Chauffeur en route',
          body: 'Votre chauffeur est en route vers le point de prise en charge.',
        };
      case TransportStatut.ARRIVEE:
        return {
          title: 'Votre chauffeur est arrivé',
          body: 'Le chauffeur est arrivé à votre position de départ.',
        };
      case TransportStatut.EN_COURS:
        return {
          title: 'Trajet en cours',
          body: 'Le trajet vers la destination a commencé.',
        };
      case TransportStatut.TERMINEE:
        return {
          title: 'Trajet terminé',
          body: 'Votre course est terminée.',
        };
      case TransportStatut.ANNULEE:
        return {
          title: 'Course annulée',
          body: 'La course a été annulée.',
        };
      default:
        return {
          title: 'Mise à jour transport',
          body: `Le statut de votre course est maintenant : ${statut}.`,
        };
    }
  }

  private assertValidTransition(current: TransportStatut, next: TransportStatut) {
    const allowed: Record<TransportStatut, TransportStatut[]> = {
      [TransportStatut.EN_ATTENTE]: [TransportStatut.ACCEPTEE],
      [TransportStatut.ACCEPTEE]: [TransportStatut.EN_ROUTE],
      [TransportStatut.EN_ROUTE]: [TransportStatut.ARRIVEE],
      [TransportStatut.ARRIVEE]: [TransportStatut.EN_COURS],
      [TransportStatut.EN_COURS]: [TransportStatut.TERMINEE],
      [TransportStatut.TERMINEE]: [],
      [TransportStatut.ANNULEE]: [],
    };
    if (!allowed[current]?.includes(next)) {
      throw new BadRequestException(`Transition invalide : ${current} → ${next}`);
    }
  }

  private async estimateTrip(
    latDepart: number,
    lonDepart: number,
    latArrivee: number,
    lonArrivee: number,
  ): Promise<{ distanceKm: number; durationMinutes: number; priceTnd: number }> {
    try {
      const route = await this.mapService.getRoute(
        { lat: latDepart, lon: lonDepart },
        { lat: latArrivee, lon: lonArrivee },
      );
      const distanceKm = Math.round((route.distance / 1000) * 100) / 100;
      const durationMinutes = Math.round((route.duration / 60) * 10) / 10;
      return {
        distanceKm,
        durationMinutes,
        priceTnd: this.calculateFareTnd(distanceKm, durationMinutes),
      };
    } catch {
      const distanceKm =
        Math.round(this.haversineKm(latDepart, lonDepart, latArrivee, lonArrivee) * 100) / 100;
      const durationMinutes = Math.round(this.estimateEtaMinutesByDistance(distanceKm) * 10) / 10;
      return {
        distanceKm,
        durationMinutes,
        priceTnd: this.calculateFareTnd(distanceKm, durationMinutes),
      };
    }
  }

  private calculateFareTnd(distanceKm: number, durationMinutes: number): number {
    return computeTransportFareTnd(distanceKm, durationMinutes, {
      base: this.fareBaseTnd,
      perKm: this.farePerKmTnd,
      perMinute: this.farePerMinuteTnd,
    });
  }

  private estimateEtaMinutesByDistance(distanceKm: number): number {
    return (distanceKm / 30) * 60;
  }
}
