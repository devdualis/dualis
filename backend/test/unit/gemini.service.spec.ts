import { describe, it, expect } from 'vitest';
import { GeminiService } from '../../src/common/ai/gemini.service';

const withConfig = (values: Record<string, string>) =>
  new GeminiService({ get: (key: string) => values[key] } as any);

describe('GeminiService (Vertex AI)', () => {
  it('stays off without a GCP project, even if an old API key is set', () => {
    const saved = process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_PROJECT;
    try {
      expect(withConfig({ GEMINI_API_KEY: 'AIza-real-looking' }).isAvailable).toBe(false);
      expect(withConfig({ GOOGLE_CLOUD_PROJECT: 'your-gcp-project-id' }).isAvailable).toBe(false);
    } finally {
      if (saved !== undefined) process.env.GOOGLE_CLOUD_PROJECT = saved;
    }
  });

  it('uses Vertex AI in São Paulo by default when a project is set', () => {
    const service = withConfig({ GOOGLE_CLOUD_PROJECT: 'dualis-test' });
    expect(service.isAvailable).toBe(true);
    const client = (service as any).client;
    expect(client.vertexai).toBe(true);
    expect(client.location).toBe('southamerica-east1');
  });
});
