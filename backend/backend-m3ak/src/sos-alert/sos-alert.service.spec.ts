import { SosAlertService } from './sos-alert.service';

describe('SosAlertService', () => {
  const sosAlertModel = {
    create: jest.fn(),
    find: jest.fn(),
  };
  const sosAlertRecipientModel = {
    updateOne: jest.fn(),
    find: jest.fn(),
  };
  const emergencyContactService = {
    listAccompagnantIdsForUser: jest.fn(),
    findBeneficiaryUserIdsForAccompagnant: jest.fn(),
  };
  const notificationService = {
    notifyDriver: jest.fn(),
  };
  const sosAlertGateway = {
    emitSosCreatedForAccompagnant: jest.fn(),
  };

  let service: SosAlertService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new SosAlertService(
      sosAlertModel as never,
      sosAlertRecipientModel as never,
      emergencyContactService as never,
      notificationService as never,
      sosAlertGateway as never,
    );
  });

  it('create distribue SOS vers les accompagnants liés', async () => {
    sosAlertModel.create.mockResolvedValue({
      _id: { toString: () => 'alert1' },
      statut: 'ENVOYEE',
      latitude: 36.8,
      longitude: 10.1,
      voiceScore: 80,
      alertSource: 'VOICE_AUTO',
      createdAt: new Date('2026-04-20T10:00:00.000Z'),
    });
    emergencyContactService.listAccompagnantIdsForUser.mockResolvedValue([
      '69e611bdd6c5bc0b35a59420',
      '69e611bdd6c5bc0b35a59421',
    ]);

    await service.create('69e611b5d6c5bc0b35a5941d', {
      latitude: 36.8,
      longitude: 10.1,
      alertSource: 'VOICE_AUTO',
      voiceScore: 80,
    });

    expect(sosAlertRecipientModel.updateOne).toHaveBeenCalledTimes(2);
    expect(notificationService.notifyDriver).toHaveBeenCalledTimes(2);
    expect(sosAlertGateway.emitSosCreatedForAccompagnant).toHaveBeenCalledTimes(2);
  });

  it('findForAccompagnant retourne vide si aucune assignation et aucun bénéficiaire lié', async () => {
    sosAlertRecipientModel.find.mockReturnValue({
      sort: () => ({
        populate: () => ({
          limit: () => ({
            lean: () => ({
              exec: async () => [],
            }),
          }),
        }),
      }),
    });
    emergencyContactService.findBeneficiaryUserIdsForAccompagnant.mockResolvedValue(
      [],
    );

    const res = await service.findForAccompagnant('69e611bdd6c5bc0b35a59420');
    expect(res).toEqual([]);
  });
});
