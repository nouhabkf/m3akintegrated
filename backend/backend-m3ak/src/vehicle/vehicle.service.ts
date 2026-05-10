import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, PipelineStage } from 'mongoose';
import { Vehicle, VehicleDocument } from './schemas/vehicle.schema';
import { CreateVehicleDto } from './dto/create-vehicle.dto';
import { UpdateVehicleDto } from './dto/update-vehicle.dto';
import { UserDocument } from '../user/schemas/user.schema';
import { Role } from '../user/enums/role.enum';
import { CHAUFFEURS_SOLIDAIRES_TYPE } from '../mobilite/mobilite.constants';
import { haversineKm } from './vehicle-geo.util';

@Injectable()
export class VehicleService {
  constructor(
    @InjectModel(Vehicle.name) private vehicleModel: Model<VehicleDocument>,
  ) {}

  async create(dto: CreateVehicleDto, user: UserDocument) {
    const existing = await this.vehicleModel
      .findOne({ immatriculation: dto.immatriculation })
      .exec();
    if (existing) {
      throw new ConflictException(
        'Un véhicule avec cette immatriculation existe déjà',
      );
    }

    const accessibilite = dto.accessibilite ?? {};

    const ownerId =
      user.role === Role.ADMIN
        ? (() => {
            if (!dto.ownerId?.trim()) {
              throw new BadRequestException(
                'ownerId est requis pour la création par un administrateur',
              );
            }
            return dto.ownerId.trim();
          })()
        : user._id;

    return this.vehicleModel.create({
      ownerId,
      marque: dto.marque,
      modele: dto.modele,
      immatriculation: dto.immatriculation,
      accessibilite: {
        coffreVaste: accessibilite.coffreVaste ?? false,
        rampeAcces: accessibilite.rampeAcces ?? false,
        siegePivotant: accessibilite.siegePivotant ?? false,
        climatisation: accessibilite.climatisation ?? false,
        animalAccepte: accessibilite.animalAccepte ?? false,
      },
      photos: dto.photos ?? [],
      statut: dto.statut ?? 'EN_ATTENTE',
    });
  }

  async findAll(params?: {
    ownerId?: string;
    statut?: string;
    page?: number;
    limit?: number;
    /** Filtrer les véhicules dont le propriétaire est à ≤ maxDistanceKm (défaut 10). */
    nearLatitude?: number;
    nearLongitude?: number;
    maxDistanceKm?: number;
  }) {
    const filter: Record<string, unknown> = {};
    if (params?.ownerId) filter.ownerId = params.ownerId;
    if (params?.statut) filter.statut = params.statut;

    const page = Math.max(1, params?.page ?? 1);
    const limit = Math.min(100, Math.max(1, params?.limit ?? 20));
    const skip = (page - 1) * limit;

    const lat = params?.nearLatitude;
    const lon = params?.nearLongitude;
    const hasGeo =
      lat != null &&
      lon != null &&
      Number.isFinite(lat) &&
      Number.isFinite(lon);

    if (hasGeo) {
      const maxKm =
        params!.maxDistanceKm != null && params!.maxDistanceKm > 0
          ? Math.min(100, params!.maxDistanceKm)
          : 10;

      const pipeline: PipelineStage[] = [
        { $match: filter },
        {
          $lookup: {
            from: 'users',
            let: { oid: '$ownerId' },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ['$_id', '$$oid'] },
                },
              },
              {
                $project: {
                  password: 0,
                },
              },
            ],
            as: '_ownerArr',
          },
        },
        { $unwind: '$_ownerArr' },
        {
          $match: {
            '_ownerArr.latitude': { $ne: null, $exists: true },
            '_ownerArr.longitude': { $ne: null, $exists: true },
          },
        },
      ];

      const rows = await this.vehicleModel.aggregate(pipeline).exec();

      const withDist = rows
        .map((doc: Record<string, unknown>) => {
          const o = doc._ownerArr as {
            latitude: number;
            longitude: number;
          };
          const distanceKm = haversineKm(lat!, lon!, o.latitude, o.longitude);
          return { doc, distanceKm };
        })
        .filter((x) => x.distanceKm <= maxKm)
        .sort((a, b) => a.distanceKm - b.distanceKm);

      const total = withDist.length;
      const slice = withDist.slice(skip, skip + limit);
      const data = slice.map(({ doc }) => {
        const owner = doc._ownerArr;
        const { _ownerArr, ...rest } = doc;
        return {
          ...rest,
          ownerId: owner,
        };
      });

      return {
        data,
        total,
        page,
        limit,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      };
    }

    const [data, total] = await Promise.all([
      this.vehicleModel
        .find(filter)
        .populate('ownerId', 'nom prenom email role')
        .skip(skip)
        .limit(limit)
        .sort({ createdAt: -1 })
        .exec(),
      this.vehicleModel.countDocuments(filter).exec(),
    ]);

    return { data, total, page, limit, totalPages: Math.ceil(total / limit) || 1 };
  }

  async findOne(id: string) {
    const vehicle = await this.vehicleModel
      .findById(id)
      .populate('ownerId', 'nom prenom email role telephone')
      .exec();
    if (!vehicle) throw new NotFoundException('Véhicule non trouvé');
    return vehicle;
  }

  async findByOwner(ownerId: string) {
    return this.vehicleModel
      .find({ ownerId })
      .sort({ createdAt: -1 })
      .exec();
  }

  async update(id: string, dto: UpdateVehicleDto, user: UserDocument) {
    const vehicle = await this.vehicleModel.findById(id).exec();
    if (!vehicle) throw new NotFoundException('Véhicule non trouvé');

    const isOwner =
      vehicle.ownerId?.toString() === user._id?.toString();
    const isAdmin = user.role === Role.ADMIN;
    const isChauffeurSolidaire =
      user.role === Role.ACCOMPAGNANT &&
      user.typeAccompagnant === CHAUFFEURS_SOLIDAIRES_TYPE;

    let effectiveDto = dto;
    if (isChauffeurSolidaire && !isOwner && !isAdmin) {
      // Chauffeurs solidaires : uniquement le statut
      if (dto.statut == null) {
        throw new ForbiddenException(
          'Seul le statut peut être modifié par un Chauffeur solidaire',
        );
      }
      effectiveDto = { statut: dto.statut };
    } else if (!isOwner && !isAdmin && !isChauffeurSolidaire) {
      throw new ForbiddenException(
        'Seul le propriétaire, un administrateur ou un Chauffeur solidaire peut modifier ce véhicule',
      );
    }

    if (effectiveDto.immatriculation) {
      const existing = await this.vehicleModel
        .findOne({ immatriculation: effectiveDto.immatriculation, _id: { $ne: id } })
        .exec();
      if (existing) {
        throw new ConflictException(
          'Un véhicule avec cette immatriculation existe déjà',
        );
      }
    }

    const updateData: Record<string, unknown> = {};
    if (effectiveDto.marque != null) updateData.marque = effectiveDto.marque;
    if (effectiveDto.modele != null) updateData.modele = effectiveDto.modele;
    if (effectiveDto.immatriculation != null)
      updateData.immatriculation = effectiveDto.immatriculation;
    if (effectiveDto.photos != null) updateData.photos = effectiveDto.photos;
    if (effectiveDto.statut != null) updateData.statut = effectiveDto.statut;

    if (effectiveDto.accessibilite) {
      const accessibiliteKeys = [
        'coffreVaste',
        'rampeAcces',
        'siegePivotant',
        'climatisation',
        'animalAccepte',
      ] as const;
      for (const key of accessibiliteKeys) {
        if (effectiveDto.accessibilite![key] !== undefined) {
          (updateData as Record<string, unknown>)[`accessibilite.${key}`] =
            effectiveDto.accessibilite![key];
        }
      }
    }

    const updated = await this.vehicleModel
      .findByIdAndUpdate(id, { $set: updateData }, { new: true })
      .populate('ownerId', 'nom prenom email role')
      .exec();

    if (!updated) throw new NotFoundException('Véhicule non trouvé');
    return updated;
  }

  async remove(id: string, user: UserDocument) {
    const vehicle = await this.vehicleModel.findById(id).exec();
    if (!vehicle) throw new NotFoundException('Véhicule non trouvé');

    const isOwner = vehicle.ownerId?.toString() === user._id?.toString();
    const isAdmin = user.role === Role.ADMIN;
    if (!isOwner && !isAdmin) {
      throw new ForbiddenException('Seul le propriétaire ou un administrateur peut supprimer ce véhicule');
    }

    const result = await this.vehicleModel.findByIdAndDelete(id).exec();
    if (!result) throw new NotFoundException('Véhicule non trouvé');
  }
}
