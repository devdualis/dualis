import { Injectable, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';

@Injectable()
export class EncryptionService {
  private readonly algorithm = 'aes-256-gcm';
  private readonly key: Buffer;
  private readonly currentVersion = 'v1';

  constructor(@Inject(ConfigService) private readonly configService: ConfigService) {
    const rawKey = this.configService.get<string>('ENCRYPTION_MASTER_KEY');
    if (!rawKey) {
      throw new Error('ENCRYPTION_MASTER_KEY environment variable is missing.');
    }
    // Master key must be 32 bytes (256 bits) represented as 64 hex characters
    this.key = Buffer.from(rawKey, 'hex');
    if (this.key.length !== 32) {
      throw new Error('ENCRYPTION_MASTER_KEY must be a 64-character hex string (32 bytes).');
    }
  }

  /**
   * Encrypts plaintext into a versioned serialized string format.
   * Output: v1:<iv_hex>:<authTag_hex>:<ciphertext_hex>
   */
  encrypt(plaintext: string): string {
    if (plaintext === null || plaintext === undefined) {
      return plaintext;
    }
    if (typeof plaintext !== 'string') {
      throw new TypeError('EncryptionService.encrypt requires a string input.');
    }

    // 12 bytes IV recommended for GCM (96 bits)
    const iv = randomBytes(12);
    const cipher = createCipheriv(this.algorithm, this.key, iv);

    let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
    ciphertext += cipher.final('hex');

    const authTag = cipher.getAuthTag();

    return `${this.currentVersion}:${iv.toString('hex')}:${authTag.toString('hex')}:${ciphertext}`;
  }

  /**
   * Decrypts a serialized versioned ciphertext back to plaintext.
   * Throws Error if payload is tampered with or corrupted.
   */
  decrypt(serializedCiphertext: string): string {
    if (!serializedCiphertext) {
      return serializedCiphertext;
    }

    const parts = serializedCiphertext.split(':');
    if (parts.length !== 4) {
      throw new Error('Invalid encrypted payload format.');
    }

    const [version, ivHex, authTagHex, ciphertextHex] = parts;

    if (version !== 'v1') {
      throw new Error(`Unsupported encryption version: ${version}`);
    }

    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');

    if (iv.length !== 12 || authTag.length !== 16) {
      throw new Error('Corrupted IV or authentication tag length.');
    }

    const decipher = createDecipheriv(this.algorithm, this.key, iv);
    decipher.setAuthTag(authTag);

    let decrypted = decipher.update(ciphertextHex, 'hex', 'utf8');
    decrypted += decipher.final('utf8'); // Throws if authTag verification fails

    return decrypted;
  }
}
