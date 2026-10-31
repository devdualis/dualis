import { describe, it, expect } from 'vitest';
import { isAllowedPicture, MAX_PICTURE_BYTES } from '../../src/modules/auth/utils/picture.util';

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const dataUri = (type: string, bytes: Buffer) => `data:image/${type};base64,${bytes.toString('base64')}`;
const png = (size = 64) => Buffer.concat([PNG_SIGNATURE, Buffer.alloc(size)]);

describe('isAllowedPicture', () => {
  it('accepts no picture and the preset avatars', () => {
    expect(isAllowedPicture('')).toBe(true);
    expect(isAllowedPicture('avatar_doctor')).toBe(true);
    expect(isAllowedPicture('avatar_clinical_teal_01')).toBe(true);
  });

  it('accepts the 512x512 PNG the app sends, and JPEG or WebP images', () => {
    expect(isAllowedPicture(dataUri('png', png(1024 * 1024)))).toBe(true); // a raw 512x512 RGBA is 1 MB
    expect(isAllowedPicture(dataUri('jpeg', Buffer.concat([Buffer.from([0xff, 0xd8, 0xff, 0xe0]), Buffer.alloc(32)])))).toBe(true);
    const webp = Buffer.concat([Buffer.from('RIFF'), Buffer.alloc(4), Buffer.from('WEBP'), Buffer.alloc(32)]);
    expect(isAllowedPicture(dataUri('webp', webp))).toBe(true);
  });

  it('rejects URLs, other types, mislabeled bytes and broken base64', () => {
    expect(isAllowedPicture('https://tracker.example/pixel.png')).toBe(false);
    expect(isAllowedPicture(dataUri('svg+xml', Buffer.from('<svg onload="alert(1)"/>')))).toBe(false);
    expect(isAllowedPicture(dataUri('png', Buffer.from('<html>not a png</html>')))).toBe(false);
    expect(isAllowedPicture('data:image/png;base64,iVBORw0KGgo=\n<script>')).toBe(false);
    expect(isAllowedPicture('avatar_<script>')).toBe(false);
    expect(isAllowedPicture('x'.repeat(5 * 1024 * 1024))).toBe(false);
  });

  it('rejects images over 1.5 MB', () => {
    expect(isAllowedPicture(dataUri('png', png(MAX_PICTURE_BYTES)))).toBe(false);
  });
});
