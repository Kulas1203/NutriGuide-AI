/**
 * AI provider abstraction.
 *
 * The orchestrator depends only on this interface, so the model vendor can be
 * swapped or given a fallback without leaking credentials to the client. The
 * initial production implementation targets Anthropic's Claude
 * (anthropicProvider.ts); a stub provider is available for local development.
 */

export interface CoachSource {
  title: string;
  source: string;
  date?: string;
}

/** Structured answer contract returned to the app. */
export interface CoachAnswer {
  text: string;
  explanation?: string;
  nextSteps: string[];
  limitations?: string;
  sources: CoachSource[];
  /** 'established' | 'general' | 'individual' | 'uncertain' */
  confidence: string;
  professionalReferral: boolean;
}

export interface GroundingChunk {
  title: string;
  source: string;
  date?: string;
  content: string;
}

export interface CoachRequest {
  question: string;
  systemPrompt: string;
  grounding: GroundingChunk[];
  history: Array<{ role: 'user' | 'coach'; text: string }>;
  /** Non-empty when the safety layer flagged a caution category. */
  cautionNote?: string;
  maxOutputTokens: number;
}

export interface AiProvider {
  readonly name: string;
  /** Streams incremental text; resolves to the final structured answer. */
  generate(
    req: CoachRequest,
    onDelta: (partialText: string) => void
  ): Promise<CoachAnswer>;
}

export class AiProviderError extends Error {
  constructor(
    message: string,
    readonly retryable: boolean
  ) {
    super(message);
    this.name = 'AiProviderError';
  }
}
