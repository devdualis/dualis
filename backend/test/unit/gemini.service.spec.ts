import { describe, it, expect, vi } from 'vitest';
import { GeminiService } from '../../src/common/ai/gemini.service';

const withConfig = (values: Record<string, string>) =>
  new GeminiService({ get: (key: string) => values[key] } as any);

describe('GeminiService (Vertex AI)', () => {
  it('stays off without a GCP project, even if an old API key is set', () => {
    const keys = ['VERTEX_PROJECT', 'GOOGLE_CLOUD_PROJECT'] as const;
    const saved = keys.map((k) => process.env[k]);
    keys.forEach((k) => delete process.env[k]);
    try {
      expect(withConfig({ GEMINI_API_KEY: 'AIza-real-looking' }).isAvailable).toBe(false);
      expect(withConfig({ VERTEX_PROJECT: 'your-gcp-project-id' }).isAvailable).toBe(false);
    } finally {
      keys.forEach((k, i) => saved[i] !== undefined && (process.env[k] = saved[i]));
    }
  });

  it('uses Vertex AI in São Paulo by default when a project is set', () => {
    const saved = process.env.VERTEX_LOCATION;
    delete process.env.VERTEX_LOCATION;
    const service = withConfig({ VERTEX_PROJECT: 'dualis-test' });
    if (saved !== undefined) process.env.VERTEX_LOCATION = saved;
    expect(service.isAvailable).toBe(true);
    const client = (service as any).client;
    expect(client.vertexai).toBe(true);
    expect(client.location).toBe('southamerica-east1');
  });

  describe('generateJson time budget', () => {
    const withClient = (generateContent: ReturnType<typeof vi.fn>) => {
      const service = withConfig({ VERTEX_PROJECT: 'dualis-test' });
      (service as any).client = { models: { generateContent } };
      return service;
    };
    const busy = () => Object.assign(new Error('429 RESOURCE_EXHAUSTED'), { status: 429 });

    it('without timeoutMs passes no abort signal (existing callers unchanged)', async () => {
      const generateContent = vi.fn().mockResolvedValue({ text: '{"a":1}' });
      expect(await withClient(generateContent).generateJson({ prompt: 'x' })).toEqual({ a: 1 });
      expect('abortSignal' in generateContent.mock.calls[0][0].config).toBe(false);
    });

    it('with timeoutMs passes one AbortSignal to every attempt', async () => {
      const generateContent = vi.fn().mockRejectedValueOnce(busy()).mockResolvedValueOnce({ text: '{"ok":true}' });
      expect(await withClient(generateContent).generateJson({ prompt: 'x', timeoutMs: 5000 })).toEqual({ ok: true });
      expect(generateContent).toHaveBeenCalledTimes(2);
      const [first, second] = generateContent.mock.calls.map((c) => c[0].config.abortSignal);
      expect(first).toBeInstanceOf(AbortSignal);
      expect(second).toBe(first);
      expect(first.aborted).toBe(false);
    });

    it('once the signal has aborted, no other attempt starts and the call rejects', async () => {
      const generateContent = vi.fn().mockImplementation(
        () => new Promise((_resolve, reject) => setTimeout(() => reject(busy()), 40)),
      );
      await expect(withClient(generateContent).generateJson({ prompt: 'x', timeoutMs: 10 })).rejects.toThrow();
      expect(generateContent).toHaveBeenCalledTimes(1);
    });

    it('an abort during the wait between attempts stops the retries too', async () => {
      const generateContent = vi.fn().mockRejectedValue(busy());
      const started = Date.now();
      await expect(withClient(generateContent).generateJson({ prompt: 'x', timeoutMs: 30 })).rejects.toThrow();
      expect(generateContent).toHaveBeenCalledTimes(1);
      expect(Date.now() - started).toBeLessThan(200);
    });
  });
});
