/**
 * Authoritative server-side safety layer for the AI Nutrition Coach.
 *
 * This mirrors the client pre-screen (app/lib/features/coach/domain/
 * safety_classifier.dart) but is the source of truth: even if a compromised
 * client bypasses its own screen, the backend refuses to return a detailed
 * diet answer for high-risk inputs and instead returns safe guidance.
 *
 * Versioned so evaluations (ai_evals/) can pin behavior. Bump SAFETY_VERSION
 * whenever the patterns or messages change, and re-run the eval suite before
 * shipping.
 */

export const SAFETY_VERSION = 'safety-v1';

export type SafetyCategory =
  | 'emergency'
  | 'selfHarm'
  | 'eatingDisorder'
  | 'dangerousFasting'
  | 'severeRestriction'
  | 'childDieting'
  | 'pregnancy'
  | 'medication'
  | 'diseaseManagement'
  | 'none';

export type SafetyAction =
  | 'blockEmergency'
  | 'blockRefer'
  | 'allowWithCaution'
  | 'allow';

export interface SafetyResult {
  category: SafetyCategory;
  action: SafetyAction;
  message?: string;
}

export const SAFETY_MESSAGES: Record<Exclude<SafetyCategory, 'none'>, string> = {
  emergency:
    'Some of what you described can be signs of a medical emergency. Please ' +
    'contact your local emergency number or seek immediate medical care now. ' +
    'This app cannot help with urgent symptoms.',
  selfHarm:
    'It sounds like you might be going through something really hard. Please ' +
    'reach out to a mental-health professional, someone you trust, or a ' +
    'crisis line in your country (in the Philippines, the NCMH Crisis ' +
    'Hotline at 1553; internationally, findahelpline.com). You deserve ' +
    'support from a real person.',
  eatingDisorder:
    'Some of what you wrote sounds like it could relate to a difficult ' +
    'relationship with food, and calorie or diet advice would not be the ' +
    'right thing to give. A physician, a registered dietitian, or an ' +
    'eating-disorder helpline can offer real support.',
  dangerousFasting:
    'NutriGuide supports gentle fasting schedules only (up to 16:8). Longer ' +
    'or stricter fasting can be risky and is not something we will help ' +
    'plan. Please talk to a physician first.',
  severeRestriction:
    'We cannot help plan intakes that low — eating far below your estimated ' +
    'needs can be harmful. A registered dietitian or physician can supervise ' +
    'safe options.',
  childDieting:
    'NutriGuide is designed for adults (18+). Diet plans for children and ' +
    'teenagers need professional supervision — please consult a pediatrician ' +
    'or registered dietitian.',
  pregnancy:
    'Nutrition during pregnancy or breastfeeding needs individual ' +
    'professional guidance, so we will keep this general. Please review any ' +
    'diet change with your OB or midwife.',
  medication:
    'Questions involving medication — doses, timing, stopping, or food ' +
    'interactions — must go to your physician or pharmacist. Nothing we say ' +
    'should change how you take a prescribed medicine.',
  diseaseManagement:
    'Managing a diagnosed condition with diet needs personalized ' +
    'professional care, so we will keep our answer general and encourage you ' +
    'to work with your care team or a registered dietitian.',
};

const BLOCKING: Array<[SafetyCategory, RegExp]> = [
  [
    'emergency',
    /(chest pain|can'?t breathe|cannot breathe|passing out|passed out|fainted|fainting|keep vomiting|vomiting blood|severe (pain|weakness)|heart attack|stroke|unconscious|seizure)/i,
  ],
  [
    'selfHarm',
    /(kill myself|end my life|suicide|self.?harm|hurt myself|don'?t want to (live|be alive)|starve myself to death)/i,
  ],
  [
    'eatingDisorder',
    /(purge|purging|throw up after (eating|meals)|make myself (sick|vomit)|laxative.* (to )?lose|hate my body so much|punish myself for eating|chew and spit|terrified of (food|eating|calories))/i,
  ],
  [
    'dangerousFasting',
    /(fast(ing)? for (more than )?(2|3|4|5|6|7|\d{2,}) days|\d+[ -]?days?[ -](water |dry )?fast|(48|72|96)[ -]?hours? fast|dry fast|water fast|not eat(en|ing)? for \d+ days|multi.?day fast)/i,
  ],
  [
    'severeRestriction',
    /((300|400|500|600|700|800)\s?(k?cal|calories)( a| per)? day|eat (almost )?nothing|zero calorie diet|starvation diet|lose \d+ ?kg in (a|one|1|2|two) week)/i,
  ],
  [
    'childDieting',
    /(my (son|daughter|child|kid)|for a (child|kid|teen(ager)?)|(1[0-7]|[5-9])[ -]?year[ -]?old).{0,40}(diet|weight|calorie|lose|slim)/i,
  ],
];

const CAUTION: Array<[SafetyCategory, RegExp]> = [
  [
    'medication',
    /(insulin|metformin|warfarin|blood thinner|dosage|my medication|stop taking|skip my (meds|medication|dose)|prescri(bed|ption))/i,
  ],
  [
    'diseaseManagement',
    /(diabet(es|ic)|kidney (disease|failure)|dialysis|liver (disease|cirrhosis)|heart (disease|failure)|cancer|chemo(therapy)?|hypertension|high blood pressure|thyroid)/i,
  ],
  ['pregnancy', /(pregnan(t|cy)|breastfeeding|nursing my|trying to conceive|postpartum)/i],
];

export function classify(message: string): SafetyResult {
  const text = (message ?? '').trim();
  if (!text) return { category: 'none', action: 'allow' };

  for (const [category, pattern] of BLOCKING) {
    if (pattern.test(text)) {
      const action: SafetyAction =
        category === 'emergency' || category === 'selfHarm'
          ? 'blockEmergency'
          : 'blockRefer';
      return {
        category,
        action,
        message: SAFETY_MESSAGES[category as Exclude<SafetyCategory, 'none'>],
      };
    }
  }
  for (const [category, pattern] of CAUTION) {
    if (pattern.test(text)) {
      return {
        category,
        action: 'allowWithCaution',
        message: SAFETY_MESSAGES[category as Exclude<SafetyCategory, 'none'>],
      };
    }
  }
  return { category: 'none', action: 'allow' };
}
