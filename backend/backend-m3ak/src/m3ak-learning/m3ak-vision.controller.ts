import {
  BadRequestException,
  Controller,
  Get,
  HttpException,
  HttpStatus,
  Post,
  ServiceUnavailableException,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { M3akVisionService } from './m3ak-vision.service';

const upload = memoryStorage();
const maxBytes = 12 * 1024 * 1024;

@ApiTags('M3AK Vision')
@Controller('m3ak')
export class M3akVisionController {
  constructor(private readonly vision: M3akVisionService) {}

  @Get()
  @ApiOperation({
    summary: 'Santé du sous-API M3AK (remplace GET / sur FastAPI:8000)',
  })
  health() {
    return this.vision.getHealth();
  }

  @Post('sign/explain')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: upload,
      limits: { fileSize: maxBytes },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiOperation({ summary: 'Analyse image → signe (MediaPipe Hands via TFJS)' })
  async explainSign(@UploadedFile() file?: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Image vide ou champ file manquant.');
    }
    try {
      return await this.vision.explainSign(file.buffer);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes('indisponible')) {
        throw new ServiceUnavailableException(msg);
      }
      throw new HttpException(msg, HttpStatus.BAD_REQUEST);
    }
  }

  @Post('face/detect')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: upload,
      limits: { fileSize: maxBytes },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiOperation({ summary: 'Détection visage (BlazeFace)' })
  async faceDetect(@UploadedFile() file?: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Image vide ou champ file manquant.');
    }
    try {
      return await this.vision.detectFace(file.buffer);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes('indisponible')) {
        throw new ServiceUnavailableException(msg);
      }
      throw new HttpException(msg, HttpStatus.BAD_REQUEST);
    }
  }

  @Post('face/encode')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: upload,
      limits: { fileSize: maxBytes },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiOperation({ summary: 'Embedding visage (crop 16×16 → vecteur 384)' })
  async faceEncode(@UploadedFile() file?: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Image vide ou champ file manquant.');
    }
    try {
      return await this.vision.encodeFace(file.buffer);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes('indisponible')) {
        throw new ServiceUnavailableException(msg);
      }
      throw new HttpException(msg, HttpStatus.BAD_REQUEST);
    }
  }

  @Post('face/emotion')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: upload,
      limits: { fileSize: maxBytes },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @ApiOperation({ summary: 'Émotion approximative (landmarks BlazeFace)' })
  async faceEmotion(@UploadedFile() file?: Express.Multer.File) {
    if (!file?.buffer?.length) {
      throw new BadRequestException('Image vide ou champ file manquant.');
    }
    try {
      return await this.vision.detectEmotion(file.buffer);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes('indisponible')) {
        throw new ServiceUnavailableException(msg);
      }
      throw new HttpException(msg, HttpStatus.BAD_REQUEST);
    }
  }
}
