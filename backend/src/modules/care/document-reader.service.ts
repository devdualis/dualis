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
    title: {
      type: 'string',
      description: 'Exam name as printed, e.g. "Hemograma completo". If the document has several exams, their names joined with ", ".',
    },
    labName: { type: 'string', description: 'Laboratory name as printed, often in the logo, header or footer (e.g. "Vita Gene").' },
    collectedOn: { type: 'string', description: 'Collection date ("Data Coleta", "Coleta", "Data da coleta") as YYYY-MM-DD, only if printed.' },
    values: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          section: { type: 'string', description: 'Heading of the exam this row belongs to, as printed (e.g. "HEMOGRAMA COMPLETO", "FERRITINA").' },
          item: { type: 'string', description: 'Analyte name exactly as printed. Never a number.' },
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
  'Each line of the OCR text is one printed line; " | " separates columns.',
  'When one row prints two results (for example "38 %" and "1.938 /mm³") with two references, return two entries with the same item name, each with its own value, unit and reference.',
  'A document can hold several exams, each under its own heading: set "section" to the heading of every row. Results printed as "Resultado" take the heading as item name.',
  'Always copy the reference text printed for an item (for example "Desejável: inferior a 190"); copying it is not a judgment.',
  'Never judge, compare, flag or explain anything. Do not say whether a value is high, low, normal or altered.',
  'For prescriptions, copy the instructions as written. Never turn them into times, doses or schedules.',
  'If something is not printed or is unreadable, leave it out. Return only the JSON schema fields.',
].join('\n');

/**
 * Identifying lines (person, doctor, documents) are removed before the text reaches
 * Gemini. A line goes when any of its columns (" | ") starts with one of these labels.
 */
const IDENTIFYING_LABEL = /^\s*(paciente|nome|name|nombre|cliente|cpf|rg|cns|cart[aã]o sus|m[eé]dic[oa]|doctor|dr\.?|dra\.?|crm|crbm|crf|liberado por|assinado|respons[aá]vel|endere[cç]o|address|direcci[oó]n|telefone|phone|tel[eé]fono|data de nascimento|nascimento|nasc|birth|fecha de nacimiento)\b/i;
const CPF = /\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/g;

export function redactIdentifiers(text: string): string {
  return text
    .split('\n')
    .filter((line) => !line.split(' | ').some((cell) => IDENTIFYING_LABEL.test(cell)))
    .join('\n')
    .replace(CPF, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

/** Keeps only schema fields with non-empty strings (drops anything the model adds). */
export function sanitizeReading(kind: 'lab' | 'prescription', raw: any): DocumentReading {
  // " | " is the column separator of the OCR layout, never part of a printed value.
  const str = (v: unknown, max: number) => {
    const text = typeof v === 'string' ? v.replace(/\s*\|\s*/g, ' ').trim() : '';
    return text ? text.slice(0, max) : undefined;
  };
  if (kind === 'prescription') {
    const medications = (Array.isArray(raw?.medications) ? raw.medications : [])
      .map((m: any) => ({ name: str(m?.name, 120), strength: str(m?.strength, 40), instructions: str(m?.instructions, 300) }))
      .filter((m: any) => m.name)
      .slice(0, 20);
    return { medications };
  }
  const collectedOn = isoDate(str(raw?.collectedOn, 20));
  const values = (Array.isArray(raw?.values) ? raw.values : [])
    .map((v: any) => ({
      ...(str(v?.section, 120) && { section: str(v?.section, 120) }),
      item: str(v?.item, 120),
      value: str(v?.value, 60),
      unit: str(v?.unit, 30),
      reference: str(v?.printedReference ?? v?.reference, 200),
    }))
    .filter((v: any) => v.item && v.value && !/^[\d.,\s]+$/.test(v.item))
    .slice(0, 200);
  return {
    title: shortTitle(str(raw?.title, 400)),
    labName: str(raw?.labName, 120),
    collectedOn,
    values,
  };
}

/** Long lists of exam names are cut at the last comma that fits in 120 characters. */
function shortTitle(title: string | undefined): string | undefined {
  if (!title || title.length <= 120) return title;
  const cut = title.slice(0, 120);
  return cut.lastIndexOf(', ') > 0 ? cut.slice(0, cut.lastIndexOf(', ')) : cut;
}

/** YYYY-MM-DD from "2026-05-21" or the Brazilian "21/05/2026"; anything else is dropped. */
function isoDate(text: string | undefined): string | undefined {
  if (!text) return undefined;
  const br = /^(\d{2})\/(\d{2})\/(\d{4})/.exec(text);
  const iso = br ? `${br[3]}-${br[2]}-${br[1]}` : text.slice(0, 10);
  const d = new Date(`${iso}T00:00:00Z`);
  return /^\d{4}-\d{2}-\d{2}$/.test(iso) && !isNaN(d.getTime()) && d.toISOString().startsWith(iso) ? iso : undefined;
}

interface Word { text: string; space: boolean; x0: number; x1: number; y0: number; y1: number }

/**
 * Rebuilds printed lines from Vision word boxes. The plain `text` field lists table
 * columns as separate blocks, which scrambles result rows; here words are grouped by
 * their vertical centre (after undoing the page tilt of photos), sorted left to
 * right, and wide gaps become " | ". Returns '' when the page has no layout.
 */
export function layoutText(page: any): string {
  const width = page?.width || 1;
  const height = page?.height || 1;
  const boxes: { text: string; space: boolean; pts: { x: number; y: number }[] }[] = [];
  for (const block of page?.blocks ?? []) {
    for (const para of block?.paragraphs ?? []) {
      for (const word of para?.words ?? []) {
        const text = (word?.symbols ?? []).map((s: any) => s?.text ?? '').join('');
        const norm = word?.boundingBox?.normalizedVertices;
        const pts = norm?.length === 4
          ? norm.map((v: any) => ({ x: (v.x ?? 0) * width, y: (v.y ?? 0) * height }))
          : (word?.boundingBox?.vertices ?? []).map((v: any) => ({ x: v.x ?? 0, y: v.y ?? 0 }));
        if (!text || pts.length !== 4) continue;
        boxes.push({ text, space: !!word.symbols.at(-1)?.property?.detectedBreak, pts });
      }
    }
  }
  if (!boxes.length) return '';

  // Undo the tilt with the median angle of the words' top edges.
  const angles = boxes.map(({ pts }) => Math.atan2(pts[1].y - pts[0].y, pts[1].x - pts[0].x)).sort((a, b) => a - b);
  const angle = angles[Math.floor(angles.length / 2)];
  const cos = Math.cos(-angle);
  const sin = Math.sin(-angle);
  const words: Word[] = boxes.map(({ text, space, pts }) => {
    const r = pts.map((p) => ({ x: p.x * cos - p.y * sin, y: p.x * sin + p.y * cos }));
    const xs = r.map((p) => p.x);
    const ys = r.map((p) => p.y);
    return { text, space, x0: Math.min(...xs), x1: Math.max(...xs), y0: Math.min(...ys), y1: Math.max(...ys) };
  });

  const heights = words.map((w) => w.y1 - w.y0).sort((a, b) => a - b);
  const h = heights[Math.floor(heights.length / 2)] || 1;
  const lines: { y: number; words: Word[] }[] = [];
  for (const w of [...words].sort((a, b) => a.y0 + a.y1 - (b.y0 + b.y1))) {
    const y = (w.y0 + w.y1) / 2;
    const line = lines.find((l) => Math.abs(l.y - y) < h * 0.5);
    if (line) {
      line.words.push(w);
      line.y += (y - line.y) / line.words.length;
    } else {
      lines.push({ y, words: [w] });
    }
  }
  return lines
    .sort((a, b) => a.y - b.y)
    .map(({ words: ws }) => {
      ws.sort((a, b) => a.x0 - b.x0);
      return ws
        .map((w, i) => {
          if (i === 0) return w.text;
          const prev = ws[i - 1];
          const gap = w.x0 - prev.x1;
          return (gap > h * 2.5 ? ' | ' : prev.space || gap > h * 0.4 ? ' ' : '') + w.text;
        })
        .join('');
    })
    .join('\n');
}

function pageText(annotation: any): string {
  return layoutText(annotation?.pages?.[0]) || annotation?.text || '';
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
      return (first?.responses ?? []).map((p: any) => pageText(p?.fullTextAnnotation)).join('\n\n');
    }
    return pageText(first?.fullTextAnnotation);
  }
}
