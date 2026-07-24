import { describe, it, expect } from 'vitest';
import {
  extractTextField,
  parseJsonObject,
  normalize,
} from './openAiCompatibleProvider';

describe('OpenAI-compatible streaming text extraction', () => {
  it('returns null before the text field starts', () => {
    expect(extractTextField('{"expl')).toBeNull();
    expect(extractTextField('')).toBeNull();
  });

  it('extracts a partial text value as it streams', () => {
    expect(extractTextField('{"text":"Aim for about')).toBe('Aim for about');
  });

  it('decodes JSON escape sequences', () => {
    expect(extractTextField('{"text":"line1\\nline2')).toBe('line1\nline2');
    expect(extractTextField('{"text":"a \\"quote\\"')).toBe('a "quote"');
  });

  it('does not break on an in-flight trailing backslash', () => {
    // A lone trailing backslash (escape in progress) must not throw.
    expect(extractTextField('{"text":"almost\\')).toBe('almost');
  });

  it('reads the full value once the string closes', () => {
    expect(extractTextField('{"text":"done","confidence":"general"}')).toBe(
      'done'
    );
  });
});

describe('OpenAI-compatible JSON object parsing', () => {
  it('parses a clean object', () => {
    expect(parseJsonObject('{"a":1}')).toEqual({ a: 1 });
  });

  it('tolerates surrounding whitespace or fences', () => {
    expect(parseJsonObject('```json\n{"a":1}\n```')).toEqual({ a: 1 });
  });

  it('returns null for incomplete JSON', () => {
    expect(parseJsonObject('{"a":')).toBeNull();
  });
});

describe('OpenAI-compatible answer normalization', () => {
  it('maps a well-formed answer to the CoachAnswer contract', () => {
    const answer = normalize({
      text: 'Eat more fiber.',
      explanation: 'It helps digestion.',
      nextSteps: ['Add beans', 'Choose whole grains'],
      limitations: 'General guidance only.',
      sources: [{ title: 'Lancet', source: 'The Lancet', date: '2019' }],
      confidence: 'established',
      professionalReferral: false,
    });
    expect(answer.text).toBe('Eat more fiber.');
    expect(answer.nextSteps).toHaveLength(2);
    expect(answer.sources[0].title).toBe('Lancet');
    expect(answer.confidence).toBe('established');
    expect(answer.professionalReferral).toBe(false);
  });

  it('falls back to uncertain for an invalid confidence', () => {
    expect(normalize({ text: 'x', confidence: 'super-sure' }).confidence).toBe(
      'uncertain'
    );
  });

  it('never fabricates fields from a sparse response', () => {
    const answer = normalize({ text: 'Just this.' });
    expect(answer.nextSteps).toEqual([]);
    expect(answer.sources).toEqual([]);
    expect(answer.explanation).toBeUndefined();
    expect(answer.professionalReferral).toBe(false);
  });
});
