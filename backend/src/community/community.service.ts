import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Post, PostDocument, PostType } from './schemas/post.schema';
import { Comment, CommentDocument } from './schemas/comment.schema';
import { CreatePostDto } from './dto/create-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';

@Injectable()
export class CommunityService {
  constructor(
    @InjectModel(Post.name) private postModel: Model<PostDocument>,
    @InjectModel(Comment.name) private commentModel: Model<CommentDocument>,
  ) {}

  // ========== POSTS ==========

  async createPost(userId: string, createDto: CreatePostDto): Promise<PostDocument> {
    const post = new this.postModel({
      ...createDto,
      userId,
      type: createDto.type || PostType.GENERAL,
    });
    return post.save();
  }

  async findAllPosts(type?: PostType): Promise<PostDocument[]> {
    const query = type ? { type } : {};
    return this.postModel
      .find(query)
      .populate('userId', 'nom prenom email photoProfil')
      .sort({ createdAt: -1 })
      .exec();
  }

  async findPostById(id: string): Promise<PostDocument> {
    const post = await this.postModel
      .findById(id)
      .populate('userId', 'nom prenom email photoProfil')
      .exec();

    if (!post) {
      throw new NotFoundException(`Post avec l'ID ${id} introuvable`);
    }
    return post;
  }

  async findPostsByUser(userId: string): Promise<PostDocument[]> {
    return this.postModel
      .find({ userId })
      .populate('userId', 'nom prenom email photoProfil')
      .sort({ createdAt: -1 })
      .exec();
  }

  async likePost(postId: string, userId: string): Promise<PostDocument> {
    const post = await this.postModel.findById(postId).exec();
    
    if (!post) {
      throw new NotFoundException(`Post avec l'ID ${postId} introuvable`);
    }

    const userIdObj = userId as any;
    const isLiked = post.likedBy.some(id => id.toString() === userId);

    if (isLiked) {
      // Unlike
      post.likedBy = post.likedBy.filter(id => id.toString() !== userId);
      post.likesCount = Math.max(0, post.likesCount - 1);
    } else {
      // Like
      post.likedBy.push(userIdObj);
      post.likesCount += 1;
    }

    return post.save();
  }

  async deletePost(id: string, userId: string): Promise<void> {
    const post = await this.postModel.findById(id).exec();
    
    if (!post) {
      throw new NotFoundException(`Post avec l'ID ${id} introuvable`);
    }

    if (post.userId.toString() !== userId) {
      throw new NotFoundException('Vous n\'êtes pas autorisé à supprimer ce post');
    }

    // Supprimer aussi tous les commentaires associés
    await this.commentModel.deleteMany({ postId: id }).exec();
    await this.postModel.findByIdAndDelete(id).exec();
  }

  // ========== COMMENTS ==========

  async createComment(postId: string, userId: string, createDto: CreateCommentDto): Promise<CommentDocument> {
    // Vérifier que le post existe
    const post = await this.postModel.findById(postId).exec();
    if (!post) {
      throw new NotFoundException(`Post avec l'ID ${postId} introuvable`);
    }

    const comment = new this.commentModel({
      ...createDto,
      postId,
      userId,
    });

    const savedComment = await comment.save();

    // Incrémenter le compteur de commentaires
    post.commentsCount += 1;
    await post.save();

    return savedComment.populate('userId', 'nom prenom email photoProfil');
  }

  async findCommentsByPost(postId: string): Promise<CommentDocument[]> {
    return this.commentModel
      .find({ postId })
      .populate('userId', 'nom prenom email photoProfil')
      .sort({ createdAt: 1 })
      .exec();
  }

  async findCommentById(id: string): Promise<CommentDocument> {
    const comment = await this.commentModel
      .findById(id)
      .populate('userId', 'nom prenom email photoProfil')
      .exec();

    if (!comment) {
      throw new NotFoundException(`Commentaire avec l'ID ${id} introuvable`);
    }
    return comment;
  }

  async deleteComment(id: string, userId: string): Promise<void> {
    const comment = await this.commentModel.findById(id).exec();
    
    if (!comment) {
      throw new NotFoundException(`Commentaire avec l'ID ${id} introuvable`);
    }

    if (comment.userId.toString() !== userId) {
      throw new NotFoundException('Vous n\'êtes pas autorisé à supprimer ce commentaire');
    }

    // Décrémenter le compteur de commentaires du post
    const post = await this.postModel.findById(comment.postId).exec();
    if (post) {
      post.commentsCount = Math.max(0, post.commentsCount - 1);
      await post.save();
    }

    await this.commentModel.findByIdAndDelete(id).exec();
  }
}




