import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { EduModule, EducationModuleDocument } from './schemas/education-module.schema';
import { EducationProgress, EducationProgressDocument } from './schemas/education-progress.schema';

@Injectable()
export class EducationService {
  constructor(
    @InjectModel(EduModule.name) private educationModuleModel: Model<EducationModuleDocument>,
    @InjectModel(EducationProgress.name) private educationProgressModel: Model<EducationProgressDocument>,
  ) {}

  async getModules(type?: string) {
    const filter = type ? { type } : {};
    return this.educationModuleModel.find(filter).exec();
  }

  async getModule(id: string) {
    const mod = await this.educationModuleModel.findById(id).exec();
    if (!mod) throw new NotFoundException('Module non trouvé');
    return mod;
  }

  async createModule(dto: { titre: string; type: string; niveau: string; description?: string }) {
    return this.educationModuleModel.create(dto);
  }

  async getProgress(userId: string) {
    return this.educationProgressModel
      .find({ userId: new Types.ObjectId(userId) })
      .populate('moduleId')
      .sort({ derniereActivite: -1 })
      .exec();
  }

  async updateProgress(userId: string, moduleId: string, score: number, niveauActuel: string) {
    const progress = await this.educationProgressModel
      .findOneAndUpdate(
        { userId: new Types.ObjectId(userId), moduleId: new Types.ObjectId(moduleId) },
        { $set: { score, niveauActuel, derniereActivite: new Date() } },
        { new: true, upsert: true },
      )
      .populate('moduleId')
      .exec();
    return progress;
  }
}
