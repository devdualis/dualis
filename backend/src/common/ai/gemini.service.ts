import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';

const DEFAULT_GENERATION_MODEL = 'gemini-2.5-flash';
const DEFAULT_EMBEDDING_MODEL = 'gemini-embedding-001';
/** São Paulo: keeps Gemini processing in Brazil (LGPD data residency). */
const DEFAULT_LOCATION = 'southamerica-east1';
export const EMBEDDING_DIMENSIONS = 768;

export interface GenerateJsonOptions {
  prompt: string;
  systemInstruction?: string;
  /** Gemini responseSchema (OpenAPI-style JSON Schema subset). */
  schema?: Record<string, unknown>;
  temperature?: number;
}

/**
 * Single entry point to the AI server (Gemini on Vertex AI). Every feature that needs
 * generation or embeddings (triage classification, article/symptom vectors, seeds,
 * future lab-exam parsing) must go through this service so key handling, model
 * selection and error behavior live in one place.
 *
 * Auth: a service-account key from `VERTEX_CLIENT_EMAIL` + `VERTEX_PRIVATE_KEY`
 * when set, otherwise Application Default Credentials (Cloud Run service account,
 * or `gcloud auth application-default login` locally). No API keys.
 */
@Injectable()
export class GeminiService {
  private readonly logger = new Logger(GeminiService.name);
  private readonly client: GoogleGenAI | null = null;
  private readonly generationModel: string;
  private readonly embeddingModel: string;

  constructor(@Optional() @Inject(ConfigService) private readonly configService?: ConfigService) {
    const read = (key: string) => this.configService?.get<string>(key) || process.env[key];
    const project = read('VERTEX_PROJECT') || read('GOOGLE_CLOUD_PROJECT');
    const location = read('VERTEX_LOCATION') || read('GOOGLE_CLOUD_LOCATION') || DEFAULT_LOCATION;
    const clientEmail = read('VERTEX_CLIENT_EMAIL');
    // Keys pasted into env files often carry literal "\n" instead of newlines.
    const privateKey = read('VERTEX_PRIVATE_KEY')?.replace(/\\n/g, '\n');
    const googleAuthOptions =
      clientEmail && privateKey
        ? { credentials: { client_email: clientEmail, private_key: privateKey } }
        : undefined;
    this.generationModel = read('GEMINI_MODEL') || DEFAULT_GENERATION_MODEL;
    this.embeddingModel = read('GEMINI_EMBEDDING_MODEL') || DEFAULT_EMBEDDING_MODEL;

    if (project && !project.startsWith('mock-') && !project.startsWith('your-')) {
      try {
        this.client = new GoogleGenAI({ vertexai: true, project, location, googleAuthOptions });
        this.logger.log(`Vertex AI client initialized (model: ${this.generationModel}, location: ${location})`);
      } catch (err) {
        this.logger.warn(`Failed to initialize Vertex AI client: ${(err as Error).message}`);
      }
    } else {
      this.logger.log('VERTEX_PROJECT not provided or mock; AI calls disabled, deterministic fallbacks active');
    }
  }

  get isAvailable(): boolean {
    return this.client !== null;
  }

  /**
   * Generates a JSON object. Throws if the client is unavailable or the call/parse
   * fails — callers own their fallback strategy.
   */
  async generateJson<T = Record<string, unknown>>(opts: GenerateJsonOptions): Promise<T> {
    if (!this.client) throw new Error('Gemini client not configured');
    const response = await this.client.models.generateContent({
      model: this.generationModel,
      contents: opts.prompt,
      config: {
        systemInstruction: opts.systemInstruction,
        responseMimeType: 'application/json',
        responseSchema: opts.schema as any,
        temperature: opts.temperature ?? 0,
      },
    });
    return JSON.parse(response.text || '{}') as T;
  }

  /** Returns a 768-dim embedding, or null when unavailable/failed (caller falls back). */
  async embed(text: string): Promise<number[] | null> {
    if (!this.client) return null;
    try {
      const response = await this.client.models.embedContent({
        model: this.embeddingModel,
        contents: text,
        config: { outputDimensionality: EMBEDDING_DIMENSIONS },
      });
      const values = response.embeddings?.[0]?.values;
      return Array.isArray(values) && values.length > 0 ? values : null;
    } catch (err) {
      this.logger.warn(`Gemini embedding failed: ${(err as Error).message}`);
      return null;
    }
  }
}
