import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GeminiService } from '../../common/ai/gemini.service';
import { DocumentReading } from './care.dto';

const VISION_URL = 'https://vision.googleapis.com/v1';
/** Synchronous files:annotate reads at most 5 PDF pages. */
const PDF_PAGES = [1, 2, 3, 4, 5];
const VISION_TIMEOUT_MS = 45_000;

const LAB_SCHEMA = {
  type: 'object',
  properties: {
    title: { type: 'string', description: 'Exam name as printed, e.g. "Hemograma completo".' },
    labName: { type: 'string', description: 'Laboratory name as printed.' },
    collectedOn: { type: 'string', description: 'Collection date as YYYY-MM-DD, only if printed.' },
    values: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          item: { type: 'string', description: 'Analyte name exactly as printed.' },
          value: { type: 'string', description: 'Result exactly as printed, same digits and decimal separator.' },
          unit: { type: 'string', description: 'Unit as printed.' },
          printedReference: {
            type: 'string',
            description: 'Text of the "valores de referência" column for this row, copied as printed. Empty string if none.',
          },
        },
        required: ['item', 'value', 'unit', 'printedReference'],
      },
    },
  },
  required: ['values'],
};

const PRESCRIPTION_SCHEMA = {
  type: 'object',
  properties: {
    medications: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          name: { type: 'string', description: 'Medicine name exactly as written.' },
          strength: { type: 'string', description: 'Strength as written, e.g. "50 mg".' },
          instructions: { type: 'string', description: 'How to take it, copied word for word from the prescription.' },
        },
        required: ['name'],
      },
    },
  },
  required: ['medications'],
};

const SYSTEM_INSTRUCTION = [
  'You copy text from a document into JSON. You are a transcriber, not a health professional.',
  'Copy names, values, units and reference ranges exactly as printed. Never convert units, round, fix or complete values.',
  'OCR text of tables may put each cell on its own line: rebuild each row (item, value, unit, reference) from the column order.',
  'Always copy the reference text printed for an item (for example "Desejável: inferior a 190"); copying it is not a judgment.',
  'Never judge, compare, flag or explain anything. Do not say whether a value is high, low, normal or altered.',
  'For prescriptions, copy the instructions as written. Never turn them into times, doses or schedules.',
  'If something is not printed or is unreadable, leave it out. Return only the JSON schema fields.',
].join('\n');

/** Identifying lines (person, doctor, documents) are removed before the text reaches Gemini. */
const IDENTIFYING_LINE = /^\s*(paciente|nome|name|nombre|cliente|cpf|rg|cns|cart[aã]o sus|m[eé]dic[oa]|doctor|dr\.?|dra\.?|crm|endere[cç]o|address|direcci[oó]n|telefone|phone|tel[eé]fono|data de nascimento|nascimento|birth|fecha de nacimiento)\b.*$/gim;
const CPF = /\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/g;

export function redactIdentifiers(text: string): string {
  return text.replace(IDENTIFYING_LINE, '').replace(CPF, '').replace(/\n{3,}/g, '\n\n').trim();
}

/** Keeps only schema fields with non-empty strings (drops anything the model adds). */
export function sanitizeReading(kind: 'lab' | 'prescription', raw: any): DocumentReading {
  const str = (v: unknown, max: number) => (typeof v === 'string' && v.trim() ? v.trim().slice(0, max) : undefined);
  if (kind === 'prescription') {
    const medications = (Array.isArray(raw?.medications) ? raw.medications : [])
      .map((m: any) => ({ name: str(m?.name, 120), strength: str(m?.strength, 40), instructions: str(m?.instructions, 300) }))
      .filter((m: any) => m.name)
      .slice(0, 20);
    return { medications };
  }
  const collectedOn = str(raw?.collectedOn, 10);
  const values = (Array.isArray(raw?.values) ? raw.values : [])
    .map((v: any) => ({ item: str(v?.item, 120), value: str(v?.value, 60), unit: str(v?.unit, 30), reference: str(v?.printedReference ?? v?.reference, 200) }))
    .filter((v: any) => v.item && v.value)
    .slice(0, 200);
  return {
    title: str(raw?.title, 120),
    labName: str(raw?.labName, 120),
    collectedOn: collectedOn && /^\d{4}-\d{2}-\d{2}$/.test(collectedOn) ? collectedOn : undefined,
    values,
  };
}

/**
 * Reads uploaded exams and prescriptions: Google Cloud Vision (DOCUMENT_TEXT_DETECTION,
 * photos and PDFs) extracts the text, then Gemini on Vertex AI copies it into a
 * transcription-only schema. The person confirms every field in the app.
 */
@Injectable()
export class DocumentReaderService {
  private readonly logger = new Logger(DocumentReaderService.name);

  constructor(
    @Inject(GeminiService) private readonly gemini: GeminiService,
    @Optional() @Inject(ConfigService) private readonly config?: ConfigService,
  ) {}

  private get visionKey(): string | undefined {
    return this.config?.get<string>('GOOGLE_VISION_API_KEY') || process.env.GOOGLE_VISION_API_KEY;
  }

  async read(kind: 'lab' | 'prescription', mime: string, file: Buffer): Promise<DocumentReading> {
    const text = await this.ocr(mime, file);
    if (!text.trim()) return kind === 'lab' ? { values: [] } : { medications: [] };
    if (!this.gemini.isAvailable) {
      this.logger.warn('Gemini unavailable; document left for manual entry');
      return kind === 'lab' ? { values: [] } : { medications: [] };
    }
    const raw = await this.gemini.generateJson({
      systemInstruction: SYSTEM_INSTRUCTION,
      prompt: `Document text (OCR):\n"""\n${redactIdentifiers(text).slice(0, 30_000)}\n"""`,
      schema: kind === 'lab' ? LAB_SCHEMA : PRESCRIPTION_SCHEMA,
      temperature: 0,
      thinkingBudget: 0,
    });
    return sanitizeReading(kind, raw);
  }

  async ocr(mime: string, file: Buffer): Promise<string> {
    const key = this.visionKey;
    if (!key) throw new Error('GOOGLE_VISION_API_KEY is not configured');
    const feature = [{ type: 'DOCUMENT_TEXT_DETECTION' }];
    const imageContext = { languageHints: ['pt', 'es', 'en'] };
    const content = file.toString('base64');
    const isPdf = mime === 'application/pdf';
    const body = isPdf
      ? { requests: [{ inputConfig: { content, mimeType: 'application/pdf' }, features: feature, imageContext, pages: PDF_PAGES }] }
      : { requests: [{ image: { content }, features: feature, imageContext }] };

    const res = await fetch(`${VISION_URL}/${isPdf ? 'files' : 'images'}:annotate?key=${encodeURIComponent(key)}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(VISION_TIMEOUT_MS),
    });
    if (!res.ok) throw new Error(`Vision HTTP ${res.status}`);
    const json: any = await res.json();
    const first = json?.responses?.[0];
    if (first?.error) throw new Error(`Vision error ${first.error.code ?? ''}`);
    if (isPdf) {
      return (first?.responses ?? []).map((p: any) => p?.fullTextAnnotation?.text ?? '').join('\n\n');
    }
    return first?.fullTextAnnotation?.text ?? '';
  }
}
