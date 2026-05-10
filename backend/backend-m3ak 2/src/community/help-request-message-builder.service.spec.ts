import { HelpRequestMessageBuilderService } from './help-request-message-builder.service';
import { HELP_REQUEST_PRESET_MESSAGES_FR } from './help-request-message-builder.constants';

describe('HelpRequestMessageBuilderService', () => {
  let service: HelpRequestMessageBuilderService;

  beforeEach(() => {
    service = new HelpRequestMessageBuilderService();
  });

  it('conserve un texte libre significatif tel quel', () => {
    const text = 'Je suis coincé près de la porte depuis dix minutes.';
    expect(service.buildFinalDescription({ description: text })).toBe(text);
  });

  it('motor + unsafe_access + preset blocked => message accès bloqué', () => {
    const out = service.buildFinalDescription({
      helpType: 'unsafe_access',
      requesterProfile: 'motor',
      presetMessageKey: 'blocked',
    });
    expect(out).toBe(HELP_REQUEST_PRESET_MESSAGES_FR.blocked);
  });

  it('visual + orientation => message orientation (perdu)', () => {
    const out = service.buildFinalDescription({
      helpType: 'orientation',
      requesterProfile: 'visual',
    });
    expect(out).toBe(HELP_REQUEST_PRESET_MESSAGES_FR.lost);
  });

  it('caregiver + mobility => phrase accompagnant', () => {
    const out = service.buildFinalDescription({
      helpType: 'mobility',
      requesterProfile: 'caregiver',
    });
    expect(out).toContain('personne');
    expect(out).toContain('mobilité');
  });

  it('isForAnotherPerson sans profil caregiver => phrase tiers', () => {
    const out = service.buildFinalDescription({
      helpType: 'mobility',
      isForAnotherPerson: true,
    });
    expect(out).toContain('personne');
  });

  it('ajoute les besoins accessibilité en fin de phrase', () => {
    const out = service.buildFinalDescription({
      helpType: 'other',
      needsAudioGuidance: true,
      needsSimpleLanguage: true,
    });
    expect(out).toContain('consignes orales');
    expect(out).toContain('phrases simples');
  });

  it('isMeaningfulRawDescription: trop court => faux', () => {
    expect(service.isMeaningfulRawDescription('ok')).toBe(false);
    expect(service.isMeaningfulRawDescription('assez long')).toBe(true);
  });
});
