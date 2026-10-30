import { describe, it, expect, vi, afterEach } from 'vitest';
import { DocumentReaderService, layoutText, redactIdentifiers, sanitizeReading } from '../../src/modules/care/document-reader.service';

const config = (key?: string) => ({ get: (k: string) => (k === 'GOOGLE_VISION_API_KEY' ? key : undefined) }) as any;

describe('DocumentReaderService', () => {
  afterEach(() => vi.unstubAllGlobals());

  it('removes identifying lines and CPF numbers before the text reaches Gemini', () => {
    const text = 'Paciente: Ana Souza\nCPF: 123.456.789-09\nDr. João CRM 1234\nColesterol total 212 mg/dL até 190\nRef 98765432100';
    const out = redactIdentifiers(text);
    expect(out).not.toMatch(/Ana|João|123\.456|98765432100/);
    expect(out).toContain('Colesterol total 212 mg/dL até 190');
  });

  it('keeps only schema fields and drops judgments the model might add', () => {
    const lab = sanitizeReading('lab', {
      title: 'Perfil lipídico',
      collectedOn: '15/10/2026',
      status: 'alterado',
      values: [
        { item: 'LDL', value: '138', unit: 'mg/dL', reference: 'até 130', flag: 'HIGH', comment: 'acima do ideal' },
        { item: '', value: '1' },
      ],
    });
    expect(lab).toEqual({
      title: 'Perfil lipídico',
      labName: undefined,
      collectedOn: '2026-10-15',
      values: [{ item: 'LDL', value: '138', unit: 'mg/dL', reference: 'até 130' }],
    });
    const rx = sanitizeReading('prescription', { medications: [{ name: 'Losartana', instructions: '1 comp. de 12/12h', times: ['08:00', '20:00'] }] });
    expect(rx).toEqual({ medications: [{ name: 'Losartana', strength: undefined, instructions: '1 comp. de 12/12h' }] });
  });

  it('drops columns that hold identifying labels, such as "Nasc." and "Liberado por"', () => {
    const text = [
      'Paciente : ANA SOUZA | Protocolo | 0006606',
      'Nasc. | : 14/01/1985 | Idade | : 41 Anos',
      'HEMOGRAMA COMPLETO | Data Coleta: 21/05/2026 às 08:59:20',
      'Cadastro | : 21/05/2026 | Médico(a) : Dr. Silva',
      'Liberado por : | CRBM - 6 : | 0530 Dr. Jefferson',
    ].join('\n');
    expect(redactIdentifiers(text)).toBe('HEMOGRAMA COMPLETO | Data Coleta: 21/05/2026 às 08:59:20');
  });

  it('keeps the section, reads Brazilian dates and drops rows whose item is a number', () => {
    const lab = sanitizeReading('lab', {
      title: 'HEMOGRAMA COMPLETO, FERRITINA',
      collectedOn: '31/02/2026',
      values: [
        { section: 'HEMOGRAMA COMPLETO', item: 'SEGMENTADOS', value: '38', unit: '%', printedReference: '40 a 75 %' },
        { section: 'HEMOGRAMA COMPLETO', item: 'SEGMENTADOS', value: '1.938', unit: '/mm³', printedReference: '1.440 a 9.000 /mm³' },
        { item: '1.938', value: '/mm³' },
        { section: 'FERRITINA', item: 'FERRITINA', value: '447,6', unit: 'ng/mL', printedReference: '23,9 a 336,2 ng/mL' },
      ],
    });
    expect(lab.collectedOn).toBeUndefined();
    expect(lab.title).toBeUndefined();
    expect(lab.values).toEqual([
      { section: 'HEMOGRAMA COMPLETO', item: 'SEGMENTADOS', value: '38', unit: '%', reference: '40 a 75 %' },
      { section: 'HEMOGRAMA COMPLETO', item: 'SEGMENTADOS', value: '1.938', unit: '/mm³', reference: '1.440 a 9.000 /mm³' },
      { section: 'FERRITINA', item: 'FERRITINA', value: '447,6', unit: 'ng/mL', reference: '23,9 a 336,2 ng/mL' },
    ]);
  });

  it('rebuilds table rows from Vision word boxes, also on a tilted photo', () => {
    // Columns arrive as separate blocks, as Vision returns them.
    const row = (y: number) => [['SEGMENTADOS:', 40], ['38', 200], ['%', 225], ['1.938', 300], ['/mm³', 345], ['40', 420], ['a', 440], ['75', 455], ['%', 475]]
      .map(([text, x]) => ({ text: text as string, x: x as number, y }));
    const words = [...row(100), ...[['EOSINÓFILOS:', 40], ['3', 200], ['%', 215]].map(([text, x]) => ({ text: text as string, x: x as number, y: 120 }))];
    const page = (tilt: number) => ({
      width: 600,
      height: 800,
      blocks: [...new Set(words.map((w) => w.x))].map((x) => ({
        paragraphs: [{
          words: words.filter((w) => w.x === x).map((w) => {
            const len = w.text.length * 7;
            const pts = [[w.x, w.y], [w.x + len, w.y], [w.x + len, w.y + 10], [w.x, w.y + 10]].map(([px, py]) => ({ x: px, y: py + px * tilt }));
            return {
              boundingBox: { normalizedVertices: pts.map((p) => ({ x: p.x / 600, y: p.y / 800 })) },
              symbols: [...w.text].map((c, i) => ({ text: c, ...(i === w.text.length - 1 && { property: { detectedBreak: { type: 'SPACE' } } }) })),
            };
          }),
        }],
      })),
    });
    const expected = 'SEGMENTADOS: | 38 % | 1.938 /mm³ | 40 a 75 %\nEOSINÓFILOS: | 3 %';
    expect(layoutText(page(0))).toBe(expected);
    expect(layoutText(page(0.05))).toBe(expected);
    expect(layoutText(undefined)).toBe('');
  });

  it('calls Vision DOCUMENT_TEXT_DETECTION: images:annotate for photos, files:annotate (5 pages) for PDFs', async () => {
    const fetchMock = vi.fn(async (url: string) => ({
      ok: true,
      json: async () =>
        url.includes('files:annotate')
          ? { responses: [{ responses: [{ fullTextAnnotation: { text: 'p1' } }, { fullTextAnnotation: { text: 'p2' } }] }] }
          : { responses: [{ fullTextAnnotation: { text: 'foto' } }] },
    }));
    vi.stubGlobal('fetch', fetchMock);
    const service = new DocumentReaderService({ isAvailable: false } as any, config('k1'));

    expect(await service.ocr('image/jpeg', Buffer.from('img'))).toBe('foto');
    expect(await service.ocr('application/pdf', Buffer.from('pdf'))).toBe('p1\n\np2');

    const [imgUrl, imgInit] = fetchMock.mock.calls[0] as any;
    expect(imgUrl).toBe('https://vision.googleapis.com/v1/images:annotate?key=k1');
    expect(JSON.parse(imgInit.body).requests[0].features).toEqual([{ type: 'DOCUMENT_TEXT_DETECTION' }]);
    const pdfBody = JSON.parse((fetchMock.mock.calls[1] as any)[1].body);
    expect(pdfBody.requests[0].inputConfig.mimeType).toBe('application/pdf');
    expect(pdfBody.requests[0].pages).toEqual([1, 2, 3, 4, 5]);
  });

  it('fails clearly without a key and leaves rows for manual entry when Gemini is off', async () => {
    await expect(new DocumentReaderService({ isAvailable: false } as any, config()).ocr('image/jpeg', Buffer.from('x'))).rejects.toThrow(
      'GOOGLE_VISION_API_KEY',
    );
    vi.stubGlobal('fetch', vi.fn(async () => ({ ok: true, json: async () => ({ responses: [{ fullTextAnnotation: { text: 'LDL 138' } }] }) })));
    const service = new DocumentReaderService({ isAvailable: false } as any, config('k'));
    expect(await service.read('lab', 'image/jpeg', Buffer.from('x'))).toEqual({ values: [] });
  });

  it('sends the redacted OCR text to Gemini with a transcription-only schema', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ({ ok: true, json: async () => ({ responses: [{ fullTextAnnotation: { text: 'Paciente: Ana\nLDL 138 mg/dL' } }] }) })));
    const generateJson = vi.fn(async () => ({ values: [{ item: 'LDL', value: '138', unit: 'mg/dL' }] }));
    const service = new DocumentReaderService({ isAvailable: true, generateJson } as any, config('k'));
    const out = await service.read('lab', 'image/jpeg', Buffer.from('x'));
    expect(out.values).toEqual([{ item: 'LDL', value: '138', unit: 'mg/dL', reference: undefined }]);
    const call = (generateJson.mock.calls[0] as any)[0];
    expect(call.prompt).not.toContain('Ana');
    expect(call.systemInstruction).toMatch(/Never judge/);
    expect(JSON.stringify(call.schema)).not.toMatch(/normal|high|low|flag|status/i);
  });
});
