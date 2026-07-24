import Anthropic from '@anthropic-ai/sdk';
import {
  AiProvider,
  AiProviderError,
  CoachAnswer,
  CoachRequest,
} from './provider';

/**
 * Production AI provider backed by Anthropic's Claude.
 *
 * The API key is read from the secret manager (never the client). The model
 * version is configurable via the MODEL_ID env/Remote Config so it can be
 * upgraded after passing the evaluation suite (ai_evals/), without an app
 * release. Structured output is requested as a strict JSON tool call so the
 * app always receives the CoachAnswer contract.
 */
export class AnthropicProvider implements AiProvider {
  readonly name = 'anthropic';
  private readonly client: Anthropic;
  private readonly model: string;

  constructor(apiKey: string, model: string) {
    this.client = new Anthropic({ apiKey });
    this.model = model;
  }

  async generate(
    req: CoachRequest,
    onDelta: (partialText: string) => void
  ): Promise<CoachAnswer> {
    const groundingBlock = req.grounding
      .map(
        (g, i) =>
          `[${i + 1}] ${g.title} — ${g.source}${g.date ? ` (${g.date})` : ''}\n${g.content}`
      )
      .join('\n\n');

    const system =
      `${req.systemPrompt}\n\n` +
      'Ground your answer ONLY in the reference material below and widely ' +
      'accepted nutrition science. Never invent studies, citations, nutrient ' +
      'values, or credentials. If the material does not cover the question, ' +
      'say what is generally accepted and clearly flag uncertainty.\n\n' +
      (groundingBlock
        ? `Reference material:\n${groundingBlock}`
        : 'No specific reference material was retrieved for this question.') +
      (req.cautionNote ? `\n\nSafety note to honor: ${req.cautionNote}` : '');

    const messages: Anthropic.MessageParam[] = [
      ...req.history.map((m) => ({
        role: (m.role === 'user' ? 'user' : 'assistant') as 'user' | 'assistant',
        content: m.text,
      })),
      { role: 'user' as const, content: req.question },
    ];

    let streamed = '';
    try {
      const stream = this.client.messages.stream({
        model: this.model,
        max_tokens: req.maxOutputTokens,
        system,
        messages,
        tools: [
          {
            name: 'nutrition_answer',
            description:
              'Return a structured, evidence-grounded nutrition answer.',
            input_schema: {
              type: 'object',
              properties: {
                text: { type: 'string', description: 'Direct answer.' },
                explanation: { type: 'string' },
                nextSteps: { type: 'array', items: { type: 'string' } },
                limitations: { type: 'string' },
                sources: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      title: { type: 'string' },
                      source: { type: 'string' },
                      date: { type: 'string' },
                    },
                    required: ['title', 'source'],
                  },
                },
                confidence: {
                  type: 'string',
                  enum: ['established', 'general', 'individual', 'uncertain'],
                },
                professionalReferral: { type: 'boolean' },
              },
              required: ['text', 'nextSteps', 'sources', 'confidence', 'professionalReferral'],
            },
          },
        ],
        tool_choice: { type: 'tool', name: 'nutrition_answer' },
      });

      stream.on('text', (delta) => {
        streamed += delta;
        onDelta(streamed);
      });

      const message = await stream.finalMessage();
      const toolUse = message.content.find((b) => b.type === 'tool_use');
      if (!toolUse || toolUse.type !== 'tool_use') {
        throw new AiProviderError('Model returned no structured answer', true);
      }
      return this.normalize(toolUse.input as Record<string, unknown>);
    } catch (err) {
      if (err instanceof AiProviderError) throw err;
      const status = (err as { status?: number }).status;
      // 429/5xx are retryable; 4xx (except 429) are not.
      const retryable = status === undefined || status === 429 || status >= 500;
      throw new AiProviderError(
        `Anthropic request failed: ${(err as Error).message}`,
        retryable
      );
    }
  }

  private normalize(input: Record<string, unknown>): CoachAnswer {
    return {
      text: String(input.text ?? ''),
      explanation: input.explanation ? String(input.explanation) : undefined,
      nextSteps: Array.isArray(input.nextSteps)
        ? input.nextSteps.map(String)
        : [],
      limitations: input.limitations ? String(input.limitations) : undefined,
      sources: Array.isArray(input.sources)
        ? (input.sources as Array<Record<string, unknown>>).map((s) => ({
            title: String(s.title ?? ''),
            source: String(s.source ?? ''),
            date: s.date ? String(s.date) : undefined,
          }))
        : [],
      confidence: String(input.confidence ?? 'uncertain'),
      professionalReferral: Boolean(input.professionalReferral),
    };
  }
}
