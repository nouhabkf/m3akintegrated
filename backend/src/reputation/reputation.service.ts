import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Rating, RatingDocument } from './schemas/rating.schema';
import { User, UserDocument } from '../user/schemas/user.schema';
import { CreateRatingDto } from './dto/create-rating.dto';

@Injectable()
export class ReputationService {
  constructor(
    @InjectModel(Rating.name) private ratingModel: Model<RatingDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async createRating(
    ratedUserId: string,
    raterUserId: string,
    createDto: CreateRatingDto,
  ): Promise<RatingDocument> {
    // Empêcher l'auto-évaluation
    if (ratedUserId === raterUserId) {
      throw new BadRequestException('Vous ne pouvez pas vous évaluer vous-même');
    }

    // Vérifier que l'utilisateur évalué existe
    const ratedUser = await this.userModel.findById(ratedUserId).exec();
    if (!ratedUser) {
      throw new NotFoundException(`Utilisateur avec l'ID ${ratedUserId} introuvable`);
    }

    // Vérifier si une évaluation existe déjà pour cette demande d'aide
    if (createDto.helpRequestId) {
      const existingRating = await this.ratingModel.findOne({
        ratedUserId,
        raterUserId,
        helpRequestId: createDto.helpRequestId,
      }).exec();

      if (existingRating) {
        throw new BadRequestException('Vous avez déjà évalué cette aide');
      }
    }

    const rating = new this.ratingModel({
      ...createDto,
      ratedUserId,
      raterUserId,
      verified: !!createDto.helpRequestId, // Vérifié si associé à une demande d'aide
    });

    const savedRating = await rating.save();

    // Mettre à jour la note moyenne de l'utilisateur
    await this.updateUserAverageRating(ratedUserId);

    // Ajouter des points de confiance
    await this.addTrustPoints(ratedUserId, createDto.note);

    // Vérifier et attribuer des badges
    await this.checkAndAssignBadges(ratedUserId);

    return savedRating.populate('ratedUserId', 'nom prenom email photoProfil');
  }

  async getRatingsByUser(userId: string): Promise<RatingDocument[]> {
    return this.ratingModel
      .find({ ratedUserId: userId })
      .populate('raterUserId', 'nom prenom email photoProfil')
      .populate('helpRequestId')
      .sort({ createdAt: -1 })
      .exec();
  }

  async getRatingById(id: string): Promise<RatingDocument> {
    const rating = await this.ratingModel
      .findById(id)
      .populate('ratedUserId', 'nom prenom email photoProfil')
      .populate('raterUserId', 'nom prenom email photoProfil')
      .exec();

    if (!rating) {
      throw new NotFoundException(`Évaluation avec l'ID ${id} introuvable`);
    }
    return rating;
  }

  private async updateUserAverageRating(userId: string): Promise<void> {
    const ratings = await this.ratingModel.find({ ratedUserId: userId }).exec();
    
    if (ratings.length === 0) {
      return;
    }

    const sum = ratings.reduce((acc, rating) => acc + rating.note, 0);
    const average = sum / ratings.length;

    await this.userModel.findByIdAndUpdate(userId, {
      noteMoyenne: Math.round(average * 10) / 10, // Arrondir à 1 décimale
    }).exec();
  }

  private async addTrustPoints(userId: string, note: number): Promise<void> {
    // Points de confiance basés sur la note
    let points = 0;
    if (note === 5) points = 10;
    else if (note === 4) points = 5;
    else if (note === 3) points = 2;
    else if (note === 2) points = -2;
    else if (note === 1) points = -5;

    const user = await this.userModel.findById(userId).exec();
    if (user) {
      user.trustPoints = Math.max(0, user.trustPoints + points);
      await user.save();
    }
  }

  private async checkAndAssignBadges(userId: string): Promise<void> {
    const user = await this.userModel.findById(userId).exec();
    if (!user) return;

    const badges: string[] = [...(user.badges || [])];

    // Badge "Premier pas" - Première aide fournie
    if (user.totalAidesFournies >= 1 && !badges.includes('PREMIER_PAS')) {
      badges.push('PREMIER_PAS');
    }

    // Badge "Bénévole actif" - 10 aides fournies
    if (user.totalAidesFournies >= 10 && !badges.includes('BENEVOLE_ACTIF')) {
      badges.push('BENEVOLE_ACTIF');
    }

    // Badge "Super bénévole" - 50 aides fournies
    if (user.totalAidesFournies >= 50 && !badges.includes('SUPER_BENEVOLE')) {
      badges.push('SUPER_BENEVOLE');
    }

    // Badge "Fiable" - Note moyenne >= 4.5
    if (user.noteMoyenne >= 4.5 && !badges.includes('FIABLE')) {
      badges.push('FIABLE');
    }

    // Badge "Expert" - Note moyenne >= 4.8 et >= 20 aides
    if (user.noteMoyenne >= 4.8 && user.totalAidesFournies >= 20 && !badges.includes('EXPERT')) {
      badges.push('EXPERT');
    }

    // Badge "Confiance" - Trust points >= 100
    if (user.trustPoints >= 100 && !badges.includes('CONFIANCE')) {
      badges.push('CONFIANCE');
    }

    if (badges.length !== user.badges?.length) {
      await this.userModel.findByIdAndUpdate(userId, { badges }).exec();
    }
  }

  async incrementAidesFournies(userId: string): Promise<void> {
    await this.userModel.findByIdAndUpdate(
      userId,
      { $inc: { totalAidesFournies: 1 } },
    ).exec();
    
    // Vérifier les badges après incrémentation
    await this.checkAndAssignBadges(userId);
  }

  async incrementAidesRecues(userId: string): Promise<void> {
    await this.userModel.findByIdAndUpdate(
      userId,
      { $inc: { totalAidesRecues: 1 } },
    ).exec();
  }

  async getUserReputation(userId: string) {
    const user = await this.userModel.findById(userId).exec();
    if (!user) {
      throw new NotFoundException(`Utilisateur avec l'ID ${userId} introuvable`);
    }

    const ratings = await this.ratingModel.find({ ratedUserId: userId }).exec();
    
    const ratingDistribution = {
      5: ratings.filter(r => r.note === 5).length,
      4: ratings.filter(r => r.note === 4).length,
      3: ratings.filter(r => r.note === 3).length,
      2: ratings.filter(r => r.note === 2).length,
      1: ratings.filter(r => r.note === 1).length,
    };

    return {
      noteMoyenne: user.noteMoyenne,
      trustPoints: user.trustPoints,
      badges: user.badges || [],
      totalAidesFournies: user.totalAidesFournies,
      totalAidesRecues: user.totalAidesRecues,
      totalEvaluations: ratings.length,
      ratingDistribution,
    };
  }
}




