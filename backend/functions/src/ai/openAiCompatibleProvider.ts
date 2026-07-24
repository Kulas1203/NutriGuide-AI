import OpenAI from 'openai';
import {
  AiProvider,
  AiProviderError,
  CoachAnswer,
  CoachRequest,
} from './provider';

/**
 * AI provider backed by any OpenAI-compatible chat-completions API.
 *
 * Works with Groq, DeepSeek, OpenRouter, Together, a local server, etc. — the
 * endpoint is chosen via `baseURL` and the model via `model`, both supplied
 * from server config (never the client). The API key is read from the secret
 * manager. The default deployment uses Groq's free tier.
 *
 * Structured output uses JSON mode: the model is instructed to return exactly
 * the CoachAnswer schema and the response is parsed strictly. To keep the
 * streaming UX, the incremental `text` field is extracted from the growing
 * JSON buffer and emitted via onDelta as the answer forms — rather than
 * showing the user raw JSON.
 */
export class OpenAiCompatibleProvider implements AiProvider {
  readonly name: string;
  private readonly client: OpenAI;
  private readonly model: string;

  constructor(
    apiKey: string,
    model: string,
    baseURL: string,
    name = 'openai-compatible'
  ) {
    this.client = new OpenAI({ apiKey, baseURL });
    this.model = model;
    this.name = name;
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

    // JSON mode requires the literal word "json" in the prompt and benefits
    // from an explicit example of the expected shape.
    const system =
      `${req.systemPrompt}\n\n` +
      'Ground your answer ONLY in the reference material below and widely ' +
      'accepted nutrition science. Never invent studies, citations, nutrient ' +
      'values, or credentials. If the material does not cover the question, ' +
      'say what is generally accepted and clearly flag uncertainty.\n\n' +
      (groundingBlock
        ? `Reference material:\n${groundingBlock}`
        : 'No specific reference material was retrieved for this question.') +
      (req.cautionNote ? `\n\nSafety note to honor: ${req.cautionNote}` : '') +
      '\n\nRespond with a single JSON object and nothing else, matching ' +
      'exactly this schema:\n' +
      '{\n' +
      '  "text": string,               // the direct answer\n' +
      '  "explanation": string,        // optional short explanation\n' +
      '  "nextSteps": string[],        // practical next steps\n' +
      '  "limitations": string,        // optional important limitations\n' +
      '  "sources": [{ "title": string, "source": string, "date": string }],\n' +
      '  "confidence": "established" | "general" | "individual" | "uncertain",\n' +
      '  "professionalReferral": boolean\n' +
      '}\n' +
      'Put the human-readable answer in "text" first. Only cite sources that ' +
      'appear in the reference material; otherwise return an empty array.';

    const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
      { role: 'system', content: system },
      ...req.history.map((m) => ({
        role: (m.role === 'user' ? 'user' : 'assistant') as 'user' | 'assistant',
        content: m.text,
      })),
      { role: 'user' as const, content: req.question },
    ];

    let buffer = '';
    let lastEmitted = '';
    try {
      const stream = await this.client.chat.completions.create({
        model: this.model,
        max_tokens: req.maxOutputTokens,
        temperature: 0.4,
        response_format: { type: 'json_object' },
        messages,
        stream: true,
      });

      for await (const chunk of stream) {
        const delta = chunk.choices[0]?.delta?.content ?? '';
        if (!delta) continue;
        buffer += delta;
        const partial = extractTextField(buffer);
        if (partial !== null && partial !== lastEmitted) {
          lastEmitted = partial;
          onDelta(partial);
        }
      }

      const parsed = parseJsonObject(buffer);
      if (!parsed) {
        throw new AiProviderError('Model returned no structured answer', true);
      }
      return normalize(parsed);
    } catch (err) {
      if (err instanceof AiProviderError) throw err;
      const status = (err as { status?: number }).status;
      // 429/5xx are retryable; other 4xx are not.
      const retryable = status === undefined || status === 429 || status >= 500;
      throw new AiProviderError(
        `${this.name} request failed: ${(err as Error).message}`,
        retryable
      );
    }
  }
}

/**
 * Incrementally extracts the value of the top-level `"text"` field from a
 * possibly-incomplete JSON string, decoding JSON escape sequences. Returns null
 * until the field has begun streaming. Exported for unit testing.
 */
export function extractTextField(buffer: string): string | null {
  const match = /"text"\s*:\s*"((?:[^"\\]|\\.)*)/.exec(buffer);
  if (!match) return null;
  try {
    // Wrap in quotes and let JSON decode the escapes; strip a trailing partial
    // escape so an in-flight "\\" never breaks parsing.
    const raw = match[1].replace(/\\$/, '');
    return JSON.parse(`"${raw}"`) as string;
  } catch {
    return null;
  }
}

/** Parses a JSON object, tolerating leading/trailing whitespace or fences. */
export function parseJsonObject(buffer: string): Record<string, unknown> | null {
  const start = buffer.indexOf('{');
  const end = buffer.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    return JSON.parse(buffer.slice(start, end + 1)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

/** Normalizes arbitrary model JSON into the strict CoachAnswer contract. */
export function normalize(input: Record<string, unknown>): CoachAnswer {
  const confidence = String(input.confidence ?? 'uncertain');
  const allowed = ['established', 'general', 'individual', 'uncertain'];
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
    confidence: allowed.includes(confidence) ? confidence : 'uncertain',
    professionalReferral: Boolean(input.professionalReferral),
  };
}
