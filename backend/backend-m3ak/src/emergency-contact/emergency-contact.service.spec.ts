import { NotFoundException } from '@nestjs/common';
import { EmergencyContactService } from './emergency-contact.service';

describe('EmergencyContactService', () => {
  const emergencyContactModel = {
    distinct: jest.fn(),
  };
  const userService = {
    getAccompagnantIdByPhone: jest.fn(),
  };

  let service: EmergencyContactService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new EmergencyContactService(
      emergencyContactModel as never,
      userService as never,
    );
  });

  it('addByPhone lève 404 si aucun accompagnant trouvé', async () => {
    userService.getAccompagnantIdByPhone.mockResolvedValue(null);

    await expect(service.addByPhone('user1', '55000002')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('addByPhone délègue à add avec accompagnantId trouvé', async () => {
    userService.getAccompagnantIdByPhone.mockResolvedValue('acc1');
    const addSpy = jest.spyOn(service, 'add').mockResolvedValue({ ok: true } as never);

    const res = await service.addByPhone('user1', '55000002', 2);

    expect(addSpy).toHaveBeenCalledWith('user1', {
      accompagnantId: 'acc1',
      ordrePriorite: 2,
    });
    expect(res).toEqual({ ok: true });
  });
});
