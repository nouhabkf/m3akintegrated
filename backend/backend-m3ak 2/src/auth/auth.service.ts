import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import * as bcrypt from 'bcryptjs';
import { UserService } from '../user/user.service';
import { LoginDto } from './dto/login.dto';
import { Role } from '../user/enums/role.enum';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client | null = null;

  constructor(
    private userService: UserService,
    private jwtService: JwtService,
  ) {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (clientId) {
      this.googleClient = new OAuth2Client(clientId);
    }
  }

  async login(loginDto: LoginDto) {
    const user = await this.userService.findByEmail(loginDto.email);
    if (!user) {
      throw new UnauthorizedException('Email ou mot de passe incorrect');
    }

    const isMatch = await bcrypt.compare(loginDto.password, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Email ou mot de passe incorrect');
    }

    const token = this.generateToken(user._id.toString(), user.email);
    const userResponse = this.userService.toUserResponse(user);

    return {
      access_token: token,
      user: userResponse,
    };
  }

  async googleLogin(idToken: string) {
    if (!this.googleClient) {
      throw new UnauthorizedException('Google Login non configuré');
    }

    let ticket;
    try {
      ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
    } catch {
      throw new UnauthorizedException('Token Google invalide');
    }

    const payload = ticket.getPayload();
    if (!payload?.email) {
      throw new UnauthorizedException('Token Google invalide');
    }

    let user = await this.userService.findByEmail(payload.email);

    if (!user) {
      const randomPassword = `google-${payload.sub}-${Date.now()}`;
      const fullName = payload.name || payload.email.split('@')[0];
      const parts = fullName.split(' ');
      const prenom = parts[0] || 'User';
      const nom = parts.slice(1).join(' ') || fullName;
      const newUser = await this.userService.create(
        {
          nom,
          prenom,
          email: payload.email,
          password: randomPassword,
          telephone: payload.email,
          role: Role.HANDICAPE,
        },
        payload.picture ?? undefined,
      );
      user = await this.userService.findByIdWithPassword(String(newUser._id));
      if (!user) {
        throw new UnauthorizedException('Erreur lors de la création du compte');
      }
    }

    const token = this.generateToken(user._id.toString(), user.email);
    const userResponse = this.userService.toUserResponse(user);

    return {
      access_token: token,
      user: userResponse,
    };
  }

  getConfigTest() {
    return {
      jwtSecretConfigured: !!process.env.JWT_SECRET,
      googleClientIdConfigured: !!process.env.GOOGLE_CLIENT_ID,
    };
  }

  private generateToken(sub: string, email: string): string {
    return this.jwtService.sign({ sub, email });
  }
}
