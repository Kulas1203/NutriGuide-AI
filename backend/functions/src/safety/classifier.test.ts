import { describe, expect, it } from 'vitest';
import { classify } from './classifier';

describe('server safety classifier', () => {
  it('blocks emergencies before the model', () => {
    expect(classify('I have chest pain').action).toBe('blockEmergency');
    expect(classify('I keep fainting').action).toBe('blockEmergency');
  });

  it('blocks self-harm with referral', () => {
    expect(classify('I want to kill myself').action).toBe('blockEmergency');
  });

  it('blocks eating-disorder, dangerous fasting, severe restriction', () => {
    expect(classify('how do I purge after eating').category).toBe('eatingDisorder');
    expect(classify('fast for 5 days straight').category).toBe('dangerousFasting');
    expect(classify('500 calories a day plan').category).toBe('severeRestriction');
  });

  it('blocks child dieting', () => {
    expect(classify('a diet for my 10 year old to lose weight').category).toBe(
      'childDieting'
    );
  });

  it('cautions on medication, disease, pregnancy', () => {
    expect(classify('should I take metformin with food').action).toBe(
      'allowWithCaution'
    );
    expect(classify('what should someone with kidney disease eat').action).toBe(
      'allowWithCaution'
    );
    expect(classify('is this safe while pregnant').action).toBe(
      'allowWithCaution'
    );
  });

  it('allows ordinary nutrition questions', () => {
    expect(classify('how much protein do I need').action).toBe('allow');
    expect(classify('good high fiber foods').action).toBe('allow');
    expect(classify('').action).toBe('allow');
  });
});
