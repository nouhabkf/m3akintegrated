import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Query,
  Request,
} from '@nestjs/common';
import { CommunityService } from './community.service';
import { CreatePostDto } from './dto/create-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';
import { PostType } from './schemas/post.schema';

@Controller('community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  // ========== POSTS ==========

  @Post('posts')
  createPost(@Body() createDto: CreatePostDto, @Request() req: any) {
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.communityService.createPost(userId, createDto);
  }

  @Get('posts')
  findAllPosts(@Query('type') type?: string) {
    const postType = type ? (PostType[type.toUpperCase() as keyof typeof PostType] || undefined) : undefined;
    return this.communityService.findAllPosts(postType);
  }

  @Get('posts/:id')
  findPostById(@Param('id') id: string) {
    return this.communityService.findPostById(id);
  }

  @Post('posts/:id/like')
  likePost(@Param('id') id: string, @Request() req: any) {
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.communityService.likePost(id, userId);
  }

  @Delete('posts/:id')
  deletePost(@Param('id') id: string, @Request() req: any) {
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.communityService.deletePost(id, userId);
  }

  // ========== COMMENTS ==========

  @Post('posts/:postId/comments')
  createComment(
    @Param('postId') postId: string,
    @Body() createDto: CreateCommentDto,
    @Request() req: any,
  ) {
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.communityService.createComment(postId, userId, createDto);
  }

  @Get('posts/:postId/comments')
  findCommentsByPost(@Param('postId') postId: string) {
    return this.communityService.findCommentsByPost(postId);
  }

  @Get('comments/:id')
  findCommentById(@Param('id') id: string) {
    return this.communityService.findCommentById(id);
  }

  @Delete('comments/:id')
  deleteComment(@Param('id') id: string, @Request() req: any) {
    const userId = req.user?.id || req.user?._id || req.body.userId; // Temporaire
    return this.communityService.deleteComment(id, userId);
  }
}




