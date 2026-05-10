import { HelpPriorityService } from './help-priority.service';

describe('HelpPriorityService', () => {
  let service: HelpPriorityService;

  beforeEach(() => {
    service = new HelpPriorityService();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('computePriority: empty calm text → low', () => {
    const r = service.computePriority({ text: 'Bonjour' });
    expect(r.priority).toBe('low');
    expect(r.score).toBeLessThanOrEqual(2);
    expect(r.matchedSignals).toEqual([]);
  });

  it('computePriority: urgent keyword bumps score', () => {
    const r = service.computePriority({
      text: 'Je suis bloqué besoin de secours',
    });
    expect(r.matchedSignals.some((s) => s.startsWith('texte:mots_urgents')))
      .toBe(true);
    expect(r.score).toBeGreaterThanOrEqual(3);
  });

  it('computePriority: low urgency phrase est détectée', () => {
    const withLow = service.computePriority({
      text: 'aide pour demain pas urgent',
    });
    expect(
      withLow.matchedSignals.some((s) => s.startsWith('texte:faible_urgence')),
    ).toBe(true);
  });

  it('computePriority: nearby obstacle + alone + no helper → high or critical', () => {
    const r = service.computePriority({
      text: 'besoin aide danger perdu',
      hasNearbyObstacle: true,
      isAlone: true,
      hasAcceptedHelper: false,
      waitingMinutes: 35,
      hour: 23,
      userProfile: 'visual',
    });
    expect(['high', 'critical']).toContain(r.priority);
    expect(r.score).toBeGreaterThan(5);
    expect(r.matchedSignals).toContain('contexte:obstacle_proche');
    expect(r.matchedSignals).toContain('contexte:seul');
    expect(r.matchedSignals).toContain('contexte:pas_daidant_accepté');
  });

  it('computePriority: waiting 15–29 adds waiting>=15 only', () => {
    const r = service.computePriority({
      text: 'x',
      waitingMinutes: 20,
    });
    expect(r.matchedSignals.some((s) => s.includes('15min'))).toBe(true);
    expect(r.matchedSignals.some((s) => s.includes('30min'))).toBe(false);
  });

  it('computePriority: waiting >= 30 uses stronger bump', () => {
    const a = service.computePriority({ text: 'x', waitingMinutes: 29 });
    const b = service.computePriority({ text: 'x', waitingMinutes: 30 });
    expect(b.score).toBeGreaterThan(a.score);
  });

  it('computePriority: helpType unsafe_access ajoute signal inclusif mobilité/accès', () => {
    const r = service.computePriority({
      text: 'besoin aide sur place',
      helpType: 'unsafe_access',
    });
    expect(
      r.matchedSignals.some((s) => s.startsWith('inclusif:mobilité_accès_difficile')),
    ).toBe(true);
  });

  it('computePriority: communication sans mot urgent → modération inclusif', () => {
    const r = service.computePriority({
      text: 'bonjour',
      helpType: 'communication',
    });
    expect(
      r.matchedSignals.some((s) => s.startsWith('inclusif:communication_modérée')),
    ).toBe(true);
  });

  it('computePriority: result shape', () => {
    const r = service.computePriority({
      text: 'danger panique',
      hasAcceptedHelper: true,
    });
    expect(r).toMatchObject({
      priority: expect.any(String),
      score: expect.any(Number),
      reason: expect.any(String),
      matchedSignals: expect.any(Array),
    });
  });
});
