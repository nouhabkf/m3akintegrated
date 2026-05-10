import { Injectable } from '@nestjs/common';
import { UserService } from '../user/user.service';
import { CreateUserDto } from '../user/dto/create-user.dto';
import { UpdateUserDto } from '../user/dto/update-user.dto';

@Injectable()
export class AdminService {
  constructor(private readonly userService: UserService) {}

  async getUsers(params: {
    page?: number;
    limit?: number;
    role?: string;
    search?: string;
  }) {
    return this.userService.findAll(params);
  }

  async getUser(id: string) {
    return this.userService.findOne(id);
  }

  async createUser(createUserDto: CreateUserDto) {
    return this.userService.create(createUserDto);
  }

  async updateUser(id: string, updateUserDto: UpdateUserDto) {
    return this.userService.update(id, updateUserDto);
  }

  async deleteUser(id: string) {
    return this.userService.remove(id);
  }
}
