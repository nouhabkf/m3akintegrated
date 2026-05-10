import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { M3akPredictDto } from './dto/m3ak-predict.dto';
import { M3akUpdateProfileDto } from './dto/m3ak-update-profile.dto';
import { M3akLearningService } from './m3ak-learning.service';

/**
 * Routes compatibles avec l’ancien FastAPI M3AK (Braille / prédiction).
 * Préfixe global : /m3ak
 */
@ApiTags('M3AK Learning')
@Controller('m3ak')
export class M3akLearningController {
  constructor(private readonly m3akLearningService: M3akLearningService) {}

  @Get('next_exercise/:userId')
  @ApiOperation({ summary: 'Prochain exercice Braille (rotation par userId)' })
  getNextExercise(@Param('userId', ParseIntPipe) userId: number) {
    return this.m3akLearningService.getNextExercise(userId);
  }

  @Post('predict')
  @ApiOperation({ summary: 'Prédire difficulté / feedback (remplace POST /predict FastAPI)' })
  predict(@Body() body: M3akPredictDto) {
    return this.m3akLearningService.predict(body);
  }

  @Post('update_profile/:userId')
  @ApiOperation({ summary: 'Mise à jour profil progression Braille' })
  updateProfile(
    @Param('userId', ParseIntPipe) userId: number,
    @Body() body: M3akUpdateProfileDto,
  ) {
    return this.m3akLearningService.updateProfile(userId, body);
  }
}
