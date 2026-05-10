import { Controller, Post, Get, Body } from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { GoogleLoginDto } from './dto/google-login.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @ApiOperation({ summary: 'Connexion classique (email + mot de passe)' })
  @ApiResponse({ status: 200, description: 'Connexion réussie, retourne JWT et utilisateur' })
  @ApiResponse({ status: 400, description: 'Données invalides' })
  @ApiResponse({ status: 401, description: 'Email ou mot de passe incorrect' })
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('google')
  @ApiOperation({ summary: 'Connexion via Google OAuth2' })
  @ApiResponse({ status: 200, description: 'Connexion réussie, retourne JWT et utilisateur' })
  @ApiResponse({ status: 400, description: 'id_token manquant ou invalide' })
  @ApiResponse({ status: 401, description: 'Token Google invalide ou Google non configuré' })
  async googleLogin(@Body() googleLoginDto: GoogleLoginDto) {
    return this.authService.googleLogin(googleLoginDto.id_token);
  }

  @Get('config-test')
  @ApiOperation({ summary: 'Vérifier la configuration (JWT, Google) - pour debug' })
  @ApiResponse({ status: 200, description: 'État de la configuration (sans afficher les secrets)' })
  getConfigTest() {
    return this.authService.getConfigTest();
  }
}
