/** Largest image accepted, decoded. The app sends a 512x512 PNG, well under 1.5 MB. */
export const MAX_PICTURE_BYTES = 1.5 * 1024 * 1024;

const PRESET_ID = /^avatar_[a-z0-9_]{1,40}$/;
const DATA_URI = /^data:image\/(png|jpeg|webp);base64,([A-Za-z0-9+/]+={0,2})$/;
/** Base64 of MAX_PICTURE_BYTES plus the longest data URI prefix. */
const MAX_DATA_URI_LENGTH = Math.ceil(MAX_PICTURE_BYTES / 3) * 4 + 'data:image/jpeg;base64,'.length;

const MATCHES_TYPE: Record<string, (bytes: Buffer) => boolean> = {
  png: (b) => b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  jpeg: (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff,
  webp: (b) => b.subarray(0, 4).toString('latin1') === 'RIFF' && b.subarray(8, 12).toString('latin1') === 'WEBP',
};

/**
 * A profile picture the app can show: empty (no picture), a preset avatar ID, or a PNG, JPEG
 * or WebP data URI whose bytes are of the declared type, up to MAX_PICTURE_BYTES.
 */
export function isAllowedPicture(value: string): boolean {
  if (value === '' || PRESET_ID.test(value)) return true;
  if (value.length > MAX_DATA_URI_LENGTH) return false;
  const match = DATA_URI.exec(value);
  if (!match) return false;
  const bytes = Buffer.from(match[2], 'base64');
  return bytes.length <= MAX_PICTURE_BYTES && MATCHES_TYPE[match[1]](bytes);
}
