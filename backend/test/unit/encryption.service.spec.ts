import { describe, it, expect, beforeEach } from 'vitest';
import { ConfigService } from '@nestjs/config';
import { EncryptionService } from '../../src/common/encryption/encryption.service';

describe('EncryptionService (SEC-02: AES-256-GCM Field Encryption)', () => {
  let service: EncryptionService;
  const mockMasterKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'; // 32 bytes hex

  beforeEach(() => {
    const configService = new ConfigService({
      ENCRYPTION_MASTER_KEY: mockMasterKey,
    });
    service = new EncryptionService(configService);
  });

  it('should encrypt and decrypt a sensitive clinical symptom narrative correctly', () => {
    const rawNarrative =
      'Paciente relata dor torácica opressiva irradiando para membro superior esquerdo e sudorese.';
    const encrypted = service.encrypt(rawNarrative);

    expect(encrypted).not.toBe(rawNarrative);
    expect(encrypted.startsWith('v1:')).toBe(true);

    const decrypted = service.decrypt(encrypted);
    expect(decrypted).toBe(rawNarrative);
  });

  it('should generate unique IVs for identical plaintext inputs (No IV reuse)', () => {
    const rawText = 'Cefaleia frontal pulsátil de intensidade 4';
    const enc1 = service.encrypt(rawText);
    const enc2 = service.encrypt(rawText);

    expect(enc1).not.toBe(enc2);

    const iv1 = enc1.split(':')[1];
    const iv2 = enc2.split(':')[1];
    expect(iv1).not.toBe(iv2);

    expect(service.decrypt(enc1)).toBe(rawText);
    expect(service.decrypt(enc2)).toBe(rawText);
  });

  it('should throw an error if ciphertext or authentication tag is tampered with', () => {
    const rawText = 'Pensamentos intrusivos e ansiedade severa';
    const encrypted = service.encrypt(rawText);
    const parts = encrypted.split(':');

    // Tamper with ciphertext by altering the last hex character
    const tamperedCiphertext =
      parts[3].slice(0, -1) + (parts[3].endsWith('a') ? 'b' : 'a');
    const tamperedPayload = `${parts[0]}:${parts[1]}:${parts[2]}:${tamperedCiphertext}`;

    expect(() => service.decrypt(tamperedPayload)).toThrow();
  });

  it('should throw an error if master key is missing or length is invalid', () => {
    const invalidShortConfig = new ConfigService({
      ENCRYPTION_MASTER_KEY: 'too-short',
    });
    expect(() => new EncryptionService(invalidShortConfig)).toThrow(
      'ENCRYPTION_MASTER_KEY must be a 64-character hex string',
    );

    const missingConfig = new ConfigService({});
    expect(() => new EncryptionService(missingConfig)).toThrow(
      'ENCRYPTION_MASTER_KEY environment variable is missing.',
    );
  });
});
