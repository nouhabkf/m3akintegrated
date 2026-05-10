import { IsString, IsEnum, IsOptional } from 'class-validator';
import { PostType } from '../schemas/post.schema';

export class CreatePostDto {
  @IsString()
  contenu: string;

  @IsEnum(PostType)
  @IsOptional()
  type?: PostType;
}




