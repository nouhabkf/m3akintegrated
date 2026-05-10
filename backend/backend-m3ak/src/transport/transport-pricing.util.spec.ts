import { computeTransportFareTnd } from './transport-pricing.util';

describe('computeTransportFareTnd', () => {
  const defaults = { base: 2.5, perKm: 0.8, perMinute: 0.15 };

  it('applique base + km + minutes', () => {
    // 2.5 + 10*0.8 + 20*0.15 = 2.5 + 8 + 3 = 13.5
    expect(computeTransportFareTnd(10, 20, defaults)).toBe(13.5);
  });

  it('arrondit à 2 décimales et ne descend pas sous 0', () => {
    expect(computeTransportFareTnd(0, 0, defaults)).toBe(2.5);
    expect(computeTransportFareTnd(0.333, 0.666, defaults)).toBe(
      Math.round((2.5 + 0.333 * 0.8 + 0.666 * 0.15) * 100) / 100,
    );
  });
});
