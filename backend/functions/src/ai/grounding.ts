import { GroundingChunk } from './provider';
import { CoachContext } from './orchestrator';

/**
 * Retrieval grounding.
 *
 * Production wires this to the reviewed knowledge base in Firestore
 * (`/reference/**`): USDA FoodData Central summaries, versioned diet content,
 * approved public-health references, and the curated local-food dataset. Each
 * item carries a source, title, date, review status and version so the model
 * can cite real, verifiable material and never fabricate.
 *
 * This module intentionally contains NO nutrition facts inline — it selects
 * reviewed documents. The default implementation returns an empty set when the
 * knowledge base is not yet populated, which keeps the model honest (it will
 * say when it lacks specific sources) rather than inventing data.
 */

export interface KnowledgeStore {
  search(query: string, filters: { dietId?: string }): Promise<GroundingChunk[]>;
}

let knowledgeStore: KnowledgeStore | null = null;

/** Wired at cold start in index.ts once Firestore is available. */
export function setKnowledgeStore(store: KnowledgeStore): void {
  knowledgeStore = store;
}

export async function retrieveGrounding(
  question: string,
  context: CoachContext
): Promise<GroundingChunk[]> {
  if (!knowledgeStore) return [];
  try {
    const chunks = await knowledgeStore.search(question, {
      dietId: context.dietId,
    });
    // Cap the number of chunks to control token cost.
    return chunks.slice(0, 6);
  } catch {
    // Retrieval failure must not fabricate grounding; return none.
    return [];
  }
}
