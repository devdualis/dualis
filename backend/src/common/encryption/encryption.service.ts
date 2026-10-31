import { Injectable, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, createHmac, hkdfSync, randomBytes } from 'node:crypto';

@Injectable()
export class EncryptionService {
  private readonly algorithm = 'aes-256-gcm';
  private readonly key: Buffer;
  /** Separate key for file fingerprints, derived so the encryption key is never reused for HMAC. */
  private readonly fingerprintKey: Buffer;
  /** Separate key for the IP address kept as consent evidence. */
  private readonly ipHashKey: Buffer;
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
    this.fingerprintKey = Buffer.from(hkdfSync('sha256', this.key, Buffer.alloc(0), 'care-document-fingerprint', 32));
    this.ipHashKey = Buffer.from(hkdfSync('sha256', this.key, Buffer.alloc(0), 'consent-ip-hash', 32));
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

  /** Encrypts binary data (uploaded files). Output: iv (12) | authTag (16) | ciphertext. */
  encryptBuffer(plain: Buffer): Buffer {
    const iv = randomBytes(12);
    const cipher = createCipheriv(this.algorithm, this.key, iv);
    const ciphertext = Buffer.concat([cipher.update(plain), cipher.final()]);
    return Buffer.concat([iv, cipher.getAuthTag(), ciphertext]);
  }

  decryptBuffer(payload: Buffer): Buffer {
    if (payload.length < 28) throw new Error('Invalid encrypted buffer.');
    const decipher = createDecipheriv(this.algorithm, this.key, payload.subarray(0, 12));
    decipher.setAuthTag(payload.subarray(12, 28));
    return Buffer.concat([decipher.update(payload.subarray(28)), decipher.final()]);
  }

  /**
   * Keyed fingerprint of a file (HMAC-SHA256, hex). Equal files give equal fingerprints,
   * but nobody without the server key can compute one to check whether a file is stored.
   */
  fingerprint(plain: Buffer): string {
    return createHmac('sha256', this.fingerprintKey).update(plain).digest('hex');
  }

  /**
   * Keyed hash of an IP address (HMAC-SHA256, hex). A plain SHA-256 of an IPv4 address can be
   * reversed by hashing all 4 billion addresses; without the server key this one cannot.
   */
  hashIp(ip: string): string {
    return createHmac('sha256', this.ipHashKey).update(ip).digest('hex');
  }
}
