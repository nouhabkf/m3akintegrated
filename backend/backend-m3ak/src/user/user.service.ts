import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcryptjs';
import { existsSync, unlinkSync } from 'fs';
import { join } from 'path';
import { User, UserDocument } from './schemas/user.schema';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateAnimalDto } from './dto/update-animal.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { Role } from './enums/role.enum';
import { CHAUFFEURS_SOLIDAIRES_TYPE } from '../mobilite/mobilite.constants';
import { normalizeTunisiaPhone } from '../common/phone.util';
import { getUploadsRoot, UPLOADS_PUBLIC_PREFIX } from '../common/upload-paths';

function tryRemoveLocalProfilePhoto(stored: string | null | undefined): void {
  if (!stored || /^https?:\/\//i.test(stored.trim())) {
    return;
  }
  const rel = stored.replace(/^\/+/, '');
  if (!rel.startsWith(`${UPLOADS_PUBLIC_PREFIX}/`)) {
    return;
  }
  const abs = join(getUploadsRoot(), rel.slice(UPLOADS_PUBLIC_PREFIX.length + 1));
  try {
    if (existsSync(abs)) {
      unlinkSync(abs);
    }
  } catch {
    /* ignore */
  }
}

@Injectable()
export class UserService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async create(
    createUserDto: CreateUserDto,
    photoProfil?: string,
  ): Promise<Omit<UserDocument, 'password'>> {
    const existing = await this.userModel
      .findOne({ email: createUserDto.email.toLowerCase() })
      .exec();
    if (existing) {
      throw new ConflictException('Cet email est déjà utilisé');
    }

    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    const user = await this.userModel.create({
      ...createUserDto,
      email: createUserDto.email.toLowerCase(),
      telephoneNormalized: normalizeTunisiaPhone(createUserDto.telephone ?? null),
      password: hashedPassword,
      role: createUserDto.role ?? Role.HANDICAPE,
      photoProfil: photoProfil ?? null,
      animalAssistance: createUserDto.animalAssistance ?? false,
      disponible: createUserDto.disponible ?? false,
      noteMoyenne: 0,
      trustPoints: 0,
      statut: createUserDto.statut ?? 'ACTIF',
      langue: createUserDto.langue ?? 'fr',
    });

    return this.toUserResponse(user);
  }

  async findAll(params: {
    page?: number;
    limit?: number;
    role?: string;
    search?: string;
  }): Promise<{
    data: Omit<UserDocument, 'password'>[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }> {
    const page = Math.max(1, params.page ?? 1);
    const limit = Math.min(100, Math.max(1, params.limit ?? 10));
    const skip = (page - 1) * limit;

    const filter: Record<string, unknown> = {};
    if (params.role) {
      filter.role = params.role;
    }
    if (params.search && params.search.trim()) {
      const search = params.search.trim();
      filter.$or = [
        { email: { $regex: search, $options: 'i' } },
        { nom: { $regex: search, $options: 'i' } },
        { prenom: { $regex: search, $options: 'i' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.userModel
        .find(filter)
        .select('-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .exec()
        .then((users) => users.map((u) => this.toUserResponse(u))),
      this.userModel.countDocuments(filter).exec(),
    ]);

    return {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findOne(id: string): Promise<Omit<UserDocument, 'password'>> {
    const user = await this.userModel.findById(id).exec();
    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé');
    }
    return this.toUserResponse(user);
  }

  async findByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel
      .findOne({ email: email.toLowerCase() })
      .select('+password')
      .exec();
  }

  async findByIdWithPassword(id: string): Promise<UserDocument | null> {
    return this.userModel.findById(id).select('+password').exec();
  }

  async findAccompagnantsDisponibles(lat?: number, lon?: number): Promise<Omit<UserDocument, 'password'>[]> {
    const filter = {
      role: Role.ACCOMPAGNANT,
      disponible: true,
      statut: 'ACTIF',
      typeAccompagnant: CHAUFFEURS_SOLIDAIRES_TYPE,
    };
    const accompagnants = await this.userModel
      .find(filter)
      .select('-password')
      .sort({ noteMoyenne: -1 })
      .exec();
    return accompagnants.map((u) => this.toUserResponse(u));
  }

  async getAccompagnantIdByPhone(telephone: string): Promise<string | null> {
    const normalized = normalizeTunisiaPhone(telephone);
    if (!normalized) return null;

    const accompagnant = await this.userModel
      .findOne({
        role: Role.ACCOMPAGNANT,
        $or: [
          { telephoneNormalized: normalized },
          { telephone: normalized },
          { telephone: telephone.trim() },
        ],
      })
      .select('_id')
      .lean()
      .exec();

    return accompagnant?._id?.toString() ?? null;
  }

  async update(
    id: string,
    updateUserDto: UpdateUserDto,
    photoProfil?: string,
  ): Promise<Omit<UserDocument, 'password'>> {
    const existing = await this.userModel
      .findById(id)
      .select('photoProfil')
      .lean<{ photoProfil?: string | null }>()
      .exec();
    if (!existing) {
      throw new NotFoundException('Utilisateur non trouvé');
    }

    let nextPhoto: string | null | undefined;
    if (photoProfil !== undefined) {
      nextPhoto = photoProfil;
    } else if (Object.prototype.hasOwnProperty.call(updateUserDto, 'photoProfil')) {
      nextPhoto = updateUserDto.photoProfil ?? null;
    }

    if (nextPhoto !== undefined && existing.photoProfil !== nextPhoto) {
      tryRemoveLocalProfilePhoto(existing.photoProfil);
    }

    const update: Record<string, unknown> = { ...updateUserDto };
    if (typeof updateUserDto.telephone === 'string') {
      update.telephoneNormalized = normalizeTunisiaPhone(updateUserDto.telephone);
    }
    if (
      Object.prototype.hasOwnProperty.call(updateUserDto, 'animalAssistance') &&
      updateUserDto.animalAssistance === false
    ) {
      update.animalType = null;
      update.animalName = null;
      update.animalNotes = null;
    }
    if (photoProfil !== undefined) {
      update.photoProfil = photoProfil;
    }

    const user = await this.userModel
      .findByIdAndUpdate(id, { $set: update }, { new: true })
      .exec();

    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé');
    }

    return this.toUserResponse(user);
  }

  async updateAnimal(
    userId: string,
    dto: UpdateAnimalDto,
  ): Promise<Omit<UserDocument, 'password'>> {
    const set: Record<string, unknown> = {
      animalAssistance: dto.animalAssistance,
    };

    if (!dto.animalAssistance) {
      set.animalType = null;
      set.animalName = null;
      set.animalNotes = null;
    } else {
      set.animalType = dto.animalType!.trim();
      if (Object.prototype.hasOwnProperty.call(dto, 'animalName')) {
        const v = dto.animalName;
        set.animalName =
          v === undefined || v === null ? null : String(v).trim() || null;
      }
      if (Object.prototype.hasOwnProperty.call(dto, 'animalNotes')) {
        const v = dto.animalNotes;
        set.animalNotes =
          v === undefined || v === null ? null : String(v).trim() || null;
      }
    }

    const user = await this.userModel
      .findByIdAndUpdate(userId, { $set: set }, { new: true })
      .exec();

    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé');
    }

    return this.toUserResponse(user);
  }

  async clearProfilePhoto(id: string): Promise<Omit<UserDocument, 'password'>> {
    const existing = await this.userModel
      .findById(id)
      .select('photoProfil')
      .lean<{ photoProfil?: string | null }>()
      .exec();
    if (!existing) {
      throw new NotFoundException('Utilisateur non trouvé');
    }
    tryRemoveLocalProfilePhoto(existing.photoProfil);

    const user = await this.userModel
      .findByIdAndUpdate(id, { $set: { photoProfil: null } }, { new: true })
      .exec();

    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé');
    }

    return this.toUserResponse(user);
  }

  async updateNoteMoyenne(userId: string, noteMoyenne: number): Promise<void> {
    await this.userModel.findByIdAndUpdate(userId, { $set: { noteMoyenne } }).exec();
  }

  async addTrustPoints(userId: string, delta: number): Promise<void> {
    if (!delta) return;
    await this.userModel
      .findByIdAndUpdate(userId, { $inc: { trustPoints: delta } }, { new: true })
      .exec();
  }

  async updateLocation(userId: string, dto: UpdateLocationDto): Promise<Omit<UserDocument, 'password'>> {
    const user = await this.userModel
      .findByIdAndUpdate(
        userId,
        {
          $set: {
            latitude: dto.lat,
            longitude: dto.lon,
            lastLocationAt: new Date(),
          },
        },
        { new: true },
      )
      .exec();

    if (!user) {
      throw new NotFoundException('Utilisateur non trouvé');
    }

    return this.toUserResponse(user);
  }

  async remove(id: string): Promise<void> {
    const existing = await this.userModel.findById(id).select('photoProfil').lean().exec();
    if (!existing) {
      throw new NotFoundException('Utilisateur non trouvé');
    }
    tryRemoveLocalProfilePhoto(existing.photoProfil);

    const result = await this.userModel.findByIdAndDelete(id).exec();
    if (!result) {
      throw new NotFoundException('Utilisateur non trouvé');
    }
  }

  toUserResponse(user: UserDocument): Omit<UserDocument, 'password'> {
    const obj = user.toObject();
    delete (obj as Record<string, unknown>).password;
    return obj as Omit<UserDocument, 'password'>;
  }
}
