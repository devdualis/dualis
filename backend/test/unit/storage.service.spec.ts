import { describe, it, expect, vi } from 'vitest';
import { StorageService } from '../../src/common/storage/storage.service';

const userId = '444e4567-e89b-12d3-a456-426614174003';
const publicUrl = (name: string) =>
  `https://ref.supabase.co/storage/v1/object/public/avatars/${userId}/${name}`;

/** StorageService on a fake "avatars" bucket whose folder for `userId` holds `names`. */
function storageWith(names: string[]) {
  const files = [...names];
  const bucket = {
    list: vi.fn(async (_folder: string, options: { limit: number }) => ({
      data: files.slice(0, options.limit).map((name) => ({ name, id: name })),
      error: null,
    })),
    remove: vi.fn(async (paths: string[]) => {
      for (const path of paths) files.splice(files.indexOf(path.slice(userId.length + 1)), 1);
      return { data: [], error: null };
    }),
    upload: vi.fn(async (path: string) => ({ data: { path }, error: null })),
    getPublicUrl: vi.fn((path: string) => ({
      data: { publicUrl: `https://ref.supabase.co/storage/v1/object/public/avatars/${path}` },
    })),
  };
  const config = { get: (key: string) => (key === 'SUPABASE_AVATAR_BUCKET' ? 'avatars' : undefined) };
  const service = new StorageService(config as any);
  (service as any).supabase = {
    storage: {
      from: vi.fn(() => bucket),
      listBuckets: vi.fn(async () => ({ data: [{ name: 'avatars' }], error: null })),
    },
  };
  return { service, bucket, files };
}

describe('StorageService avatars', () => {
  it('deletes only the replaced picture, never another upload in the folder', async () => {
    // 2.jpg belongs to another save still in progress; it may become the picture in use.
    const { service, bucket, files } = storageWith(['1.png', '2.jpg', '3.webp']);

    await service.removeAvatar(userId, `${publicUrl('1.png')}?v=1`);

    expect(bucket.list).not.toHaveBeenCalled();
    expect(bucket.remove).toHaveBeenCalledWith([`${userId}/1.png`]);
    expect(files).toEqual(['2.jpg', '3.webp']);
  });

  it('leaves presets, data URIs and other people\'s files alone', async () => {
    const { service, bucket } = storageWith(['1.png']);

    await service.removeAvatar(userId, 'avatar_clinical_teal_01');
    await service.removeAvatar(userId, 'data:image/png;base64,iVBORw0KGgo=');
    await service.removeAvatar(userId, null);
    await service.removeAvatar(
      userId,
      'https://ref.supabase.co/storage/v1/object/public/avatars/someone-else/1.png',
    );

    expect(bucket.remove).not.toHaveBeenCalled();
  });

  it('deletes every picture once the account is gone', async () => {
    const { service, bucket, files } = storageWith(['1.png', '2.jpg']);

    await service.removeAvatars(userId);

    expect(bucket.list).toHaveBeenCalledWith(userId, { limit: 100 });
    expect(files).toEqual([]);
  });

  it('pages through folders with more pictures than one listing returns', async () => {
    const { service, bucket, files } = storageWith(Array.from({ length: 150 }, (_, i) => `${i}.png`));

    await service.removeAvatars(userId);

    expect(bucket.remove).toHaveBeenCalledTimes(2);
    expect(files).toEqual([]);
  });

  it('logs and never throws when storage fails', async () => {
    const { service, bucket } = storageWith(['1.png']);
    bucket.list.mockResolvedValueOnce({ data: null, error: new Error('storage down') } as any);
    bucket.remove.mockResolvedValueOnce({ data: null, error: new Error('storage down') } as any);
    const warn = vi.spyOn((service as any).logger, 'warn').mockImplementation(() => undefined);

    await expect(service.removeAvatars(userId)).resolves.toBeUndefined();
    expect(bucket.remove).not.toHaveBeenCalled();
    await expect(service.removeAvatar(userId, publicUrl('1.png'))).resolves.toBeUndefined();

    expect(warn).toHaveBeenCalledTimes(2);
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('storage down'));
  });

  it('does nothing when storage is not configured', async () => {
    const service = new StorageService({ get: () => undefined } as any);
    (service as any).supabase = null;

    await expect(service.removeAvatars(userId)).resolves.toBeUndefined();
    await expect(service.removeAvatar(userId, publicUrl('1.png'))).resolves.toBeUndefined();
  });

  it('uploads into the person\'s folder without writing the public link to the logs', async () => {
    const { service, bucket } = storageWith([]);
    const logger = (service as any).logger;
    const logs = [vi.spyOn(logger, 'log'), vi.spyOn(logger, 'debug'), vi.spyOn(logger, 'warn')];
    logs.forEach((spy) => spy.mockImplementation(() => undefined));

    const url = await service.processAvatarImage(userId, 'data:image/png;base64,iVBORw0KGgo=');

    expect(bucket.upload.mock.calls[0][0]).toMatch(new RegExp(`^${userId}/\\d+\\.png$`));
    expect(url).toContain(`/avatars/${userId}/`);
    for (const spy of logs) {
      for (const args of spy.mock.calls) expect(String(args[0])).not.toContain('https://');
    }
  });
});
