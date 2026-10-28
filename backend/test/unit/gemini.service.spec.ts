import { describe, it, expect } from 'vitest';
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
});
