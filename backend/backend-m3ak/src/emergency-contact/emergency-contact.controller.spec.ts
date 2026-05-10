import { ForbiddenException } from '@nestjs/common';
import { EmergencyContactController } from './emergency-contact.controller';
import { Role } from '../user/enums/role.enum';

describe('EmergencyContactController', () => {
  const emergencyContactService = {
    add: jest.fn(),
    addByPhone: jest.fn(),
  };

  const controller = new EmergencyContactController(
    emergencyContactService as never,
  );

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('refuse add si role non HANDICAPE', async () => {
    await expect(
      controller.add(
        { _id: 'u1', role: Role.ACCOMPAGNANT } as never,
        { accompagnantId: 'a1', ordrePriorite: 1 },
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('refuse link-by-phone si role non HANDICAPE', async () => {
    await expect(
      controller.linkByPhone(
        { _id: 'u1', role: Role.ADMIN } as never,
        { telephone: '+21655000002' },
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('link-by-phone appelle le service pour HANDICAPE', async () => {
    emergencyContactService.addByPhone.mockResolvedValue({ ok: true });

    const res = await controller.linkByPhone(
      { _id: 'u1', role: Role.HANDICAPE } as never,
      { telephone: '55000002' },
    );

    expect(emergencyContactService.addByPhone).toHaveBeenCalledWith(
      'u1',
      '55000002',
    );
    expect(res).toEqual({ ok: true });
  });
});
