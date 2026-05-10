import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Lieu, LieuDocument, LieuStatus } from './schemas/lieu.schema';
import { CreateLieuDto } from './dto/create-lieu.dto';

@Injectable()
export class LieuxService {
  constructor(
    @InjectModel(Lieu.name) private lieuModel: Model<LieuDocument>,
  ) {}

  async findAll(): Promise<LieuDocument[]> {
    return this.lieuModel
      .find({ statut: LieuStatus.APPROVED })
      .populate('createdBy', 'nom prenom email photoProfil')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findNearby(
    latitude: number,
    longitude: number,
    maxDistance: number = 10,
  ): Promise<LieuDocument[]> {
    return this.lieuModel
      .find({
        location: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [longitude, latitude], // GeoJSON: [lng, lat]
            },
            $maxDistance: maxDistance * 1000, // Convertir km en mètres
          },
        },
        statut: LieuStatus.APPROVED,
      })
      .populate('createdBy', 'nom prenom email photoProfil')
      .exec();
  }

  async findOne(id: string): Promise<LieuDocument> {
    const lieu = await this.lieuModel
      .findById(id)
      .populate('createdBy', 'nom prenom email photoProfil')
      .exec();

    if (!lieu) {
      throw new NotFoundException(`Lieu avec l'ID ${id} introuvable`);
    }

    return lieu;
  }

  async create(userId: string, createDto: CreateLieuDto): Promise<LieuDocument> {
    const lieu = new this.lieuModel({
      nom: createDto.nom,
      typeLieu: createDto.typeLieu,
      adresse: createDto.adresse,
      description: createDto.description,
      telephone: createDto.telephone,
      horaires: createDto.horaires,
      amenities: createDto.amenities,
      images: createDto.images,
      createdBy: userId,
      statut: LieuStatus.PENDING,
      location: {
        type: 'Point',
        coordinates: [createDto.longitude, createDto.latitude], // GeoJSON: [lng, lat]
      },
    });

    return lieu.save();
  }

  // Méthodes pour l'administration (à utiliser dans un module admin séparé)
  async findPending(): Promise<LieuDocument[]> {
    return this.lieuModel
      .find({ statut: LieuStatus.PENDING })
      .populate('createdBy', 'nom prenom email photoProfil')
      .sort({ createdAt: -1 })
      .exec();
  }

  async approve(id: string): Promise<LieuDocument> {
    const lieu = await this.lieuModel
      .findByIdAndUpdate(
        id,
        { statut: LieuStatus.APPROVED },
        { new: true },
      )
      .populate('createdBy', 'nom prenom email photoProfil')
      .exec();

    if (!lieu) {
      throw new NotFoundException(`Lieu avec l'ID ${id} introuvable`);
    }

    return lieu;
  }

  async reject(id: string, reason?: string): Promise<LieuDocument> {
    const lieu = await this.lieuModel
      .findByIdAndUpdate(
        id,
        { statut: LieuStatus.REJECTED },
        { new: true },
      )
      .populate('createdBy', 'nom prenom email photoProfil')
      .exec();

    if (!lieu) {
      throw new NotFoundException(`Lieu avec l'ID ${id} introuvable`);
    }

    return lieu;
  }
}





