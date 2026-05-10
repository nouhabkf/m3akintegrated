import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { HelpRequest, HelpRequestDocument, HelpRequestStatus } from './schemas/help-request.schema';
import { CreateHelpRequestDto } from './dto/create-help-request.dto';
import { UpdateHelpRequestStatusDto } from './dto/update-help-request-status.dto';
import { ReputationService } from '../reputation/reputation.service';

@Injectable()
export class HelpRequestService {
  constructor(
    @InjectModel(HelpRequest.name) private helpRequestModel: Model<HelpRequestDocument>,
    private reputationService: ReputationService,
  ) {}

  async create(userId: string, createDto: CreateHelpRequestDto): Promise<HelpRequestDocument> {
    const helpRequest = new this.helpRequestModel({
      ...createDto,
      userId,
      statut: HelpRequestStatus.EN_ATTENTE,
    });
    return helpRequest.save();
  }

  async findAll(
    page: number = 1,
    limit: number = 20,
  ): Promise<{
    data: HelpRequestDocument[];
    total: number;
    page: number;
    totalPages: number;
  }> {
    const skip = (page - 1) * limit;
    
    const [data, total] = await Promise.all([
      this.helpRequestModel
        .find()
        .populate('userId', 'nom prenom email photoProfil')
        .populate('acceptedBy', 'nom prenom email photoProfil')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec(),
      this.helpRequestModel.countDocuments().exec(),
    ]);
    
    const totalPages = Math.ceil(total / limit);
    
    return {
      data,
      total,
      page,
      totalPages,
    };
  }

  async findByUser(userId: string): Promise<HelpRequestDocument[]> {
    return this.helpRequestModel
      .find({ userId })
      .populate('userId', 'nom prenom email photoProfil')
      .populate('acceptedBy', 'nom prenom email photoProfil')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findNearby(latitude: number, longitude: number, maxDistance: number = 10): Promise<HelpRequestDocument[]> {
    // Option 1: Recherche simple avec formule de Haversine (actuelle)
    // Option 2: Utiliser MongoDB Geospatial avec $near (plus performant pour grandes bases)
    
    // Pour l'instant, on utilise la méthode simple
    // Pour activer la recherche géospatiale MongoDB native, décommenter le code ci-dessous
    // et modifier le schéma pour utiliser GeoJSON
    
    const helpRequests = await this.helpRequestModel
      .find({
        statut: HelpRequestStatus.EN_ATTENTE,
      })
      .populate('userId', 'nom prenom email photoProfil')
      .exec();

    // Filtrer par distance (formule de Haversine)
    const filtered = helpRequests.filter((hr) => {
      const distance = this.calculateDistance(
        latitude,
        longitude,
        hr.latitude,
        hr.longitude,
      );
      return distance <= maxDistance;
    });

    // Trier par distance
    return filtered.sort((a, b) => {
      const distA = this.calculateDistance(latitude, longitude, a.latitude, a.longitude);
      const distB = this.calculateDistance(latitude, longitude, b.latitude, b.longitude);
      return distA - distB;
    });

    /* 
    // ALTERNATIVE: Recherche géospatiale MongoDB native (plus performante)
    // Nécessite de modifier le schéma pour utiliser GeoJSON:
    // location: { type: { type: String, enum: ['Point'], default: 'Point' }, coordinates: [Number] }
    
    return this.helpRequestModel
      .find({
        statut: HelpRequestStatus.EN_ATTENTE,
        location: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [longitude, latitude], // Note: MongoDB utilise [longitude, latitude]
            },
            $maxDistance: maxDistance * 1000, // Convertir km en mètres
          },
        },
      })
      .populate('userId', 'nom prenom email photoProfil')
      .limit(50) // Limiter les résultats
      .exec();
    */
  }

  async findOne(id: string): Promise<HelpRequestDocument> {
    const helpRequest = await this.helpRequestModel
      .findById(id)
      .populate('userId', 'nom prenom email photoProfil')
      .populate('acceptedBy', 'nom prenom email photoProfil')
      .exec();

    if (!helpRequest) {
      throw new NotFoundException(`Demande d'aide avec l'ID ${id} introuvable`);
    }
    return helpRequest;
  }

  async updateStatus(id: string, updateDto: UpdateHelpRequestStatusDto, acceptedBy?: string): Promise<HelpRequestDocument> {
    const updateData: any = { statut: updateDto.statut };
    
    if (updateDto.statut === HelpRequestStatus.EN_COURS && acceptedBy) {
      updateData.acceptedBy = acceptedBy;
    }

    const helpRequest = await this.helpRequestModel
      .findByIdAndUpdate(id, updateData, { new: true })
      .populate('userId', 'nom prenom email photoProfil')
      .populate('acceptedBy', 'nom prenom email photoProfil')
      .exec();

    if (!helpRequest) {
      throw new NotFoundException(`Demande d'aide avec l'ID ${id} introuvable`);
    }

    // Si la demande est terminée, mettre à jour les statistiques
    if (updateDto.statut === HelpRequestStatus.TERMINEE) {
      if (helpRequest.acceptedBy) {
        // Incrémenter les aides fournies pour le bénévole
        await this.reputationService.incrementAidesFournies(helpRequest.acceptedBy.toString());
      }
      // Incrémenter les aides reçues pour le demandeur
      await this.reputationService.incrementAidesRecues(helpRequest.userId.toString());
    }

    return helpRequest;
  }

  async acceptRequest(id: string, volunteerId: string): Promise<HelpRequestDocument> {
    return this.updateStatus(id, { statut: HelpRequestStatus.EN_COURS }, volunteerId);
  }

  async delete(id: string, userId: string): Promise<void> {
    const helpRequest = await this.helpRequestModel.findById(id).exec();
    
    if (!helpRequest) {
      throw new NotFoundException(`Demande d'aide avec l'ID ${id} introuvable`);
    }

    // Vérifier que l'utilisateur est le propriétaire
    if (helpRequest.userId.toString() !== userId) {
      throw new NotFoundException('Vous n\'êtes pas autorisé à supprimer cette demande');
    }

    await this.helpRequestModel.findByIdAndDelete(id).exec();
  }

  // Calcul de distance en km (formule de Haversine)
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Rayon de la Terre en km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
