import { IsString } from 'class-validator';

export class CreateCommentDto {
  @IsString()
  contenu: string;
}




