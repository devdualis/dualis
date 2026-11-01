import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

/** Names per `list` call when deleting a person's pictures. */
const AVATAR_PAGE_SIZE = 100;
/** Bound on `list` calls per cleanup, so a folder that never empties cannot loop forever. */
const MAX_AVATAR_PAGES = 20;

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private supabase: SupabaseClient | null = null;
  private readonly bucketName: string;
  private bucketChecked = false;

  constructor(@Optional() private readonly configService?: ConfigService) {
    const supabaseUrl =
      this.configService?.get<string>('SUPABASE_URL') ||
      process.env.SUPABASE_URL;
    const supabaseKey =
      this.configService?.get<string>('SUPABASE_SERVICE_ROLE_KEY') ||
      this.configService?.get<string>('SUPABASE_ANON_KEY') ||
      this.configService?.get<string>('SUPABASE_PUBLISHABLE_KEY') ||
      process.env.SUPABASE_SERVICE_ROLE_KEY ||
      process.env.SUPABASE_ANON_KEY ||
      process.env.SUPABASE_PUBLISHABLE_KEY;

    this.bucketName =
      this.configService?.get<string>('SUPABASE_AVATAR_BUCKET') ||
      process.env.SUPABASE_AVATAR_BUCKET ||
      'avatars';

    if (supabaseUrl && supabaseKey) {
      try {
        this.supabase = createClient(supabaseUrl, supabaseKey, {
          auth: { persistSession: false },
        });
        this.logger.log(
          `Supabase Storage initialized for bucket: "${this.bucketName}"`,
        );
      } catch (err) {
        this.logger.warn(
          `Failed to initialize Supabase client: ${(err as Error).message}`,
        );
      }
    } else {
      this.logger.log(
        'No Supabase credentials found. Fallback to direct DB storage for avatars.',
      );
    }
  }

  private async ensureBucketExists(): Promise<void> {
    if (!this.supabase || this.bucketChecked) return;
    try {
      const { data: buckets, error } = await this.supabase.storage.listBuckets();
      if (error) {
        this.logger.warn(`Could not list storage buckets: ${error.message}`);
        return;
      }

      const exists = buckets?.some((b) => b.name === this.bucketName);
      if (!exists) {
        const { error: createError } = await this.supabase.storage.createBucket(
          this.bucketName,
          { public: true },
        );
        if (createError) {
          this.logger.warn(
            `Could not create bucket "${this.bucketName}": ${createError.message}`,
          );
        } else {
          this.logger.log(`Created public bucket "${this.bucketName}"`);
        }
      }
      this.bucketChecked = true;
    } catch (err) {
      this.logger.warn(
        `Error ensuring bucket exists: ${(err as Error).message}`,
      );
    }
  }

  /**
   * Processes an avatar image string:
   * - If it's a data URI (e.g. data:image/jpeg;base64,...), uploads to Supabase Storage if configured.
   * - If uploaded, returns the public cloud URL.
   * - If Supabase is not configured or upload fails, returns the data URI directly for DB storage.
   * - If it's already a preset ID (e.g. avatar_doctor) or HTTP URL, returns as-is.
   */
  async processAvatarImage(userId: string, picture: string): Promise<string> {
    if (!picture || !picture.startsWith('data:image')) {
      return picture;
    }

    if (!this.supabase) {
      this.logger.debug(
        `Saving avatar directly to database as data URI for user ${userId}`,
      );
      return picture;
    }

    try {
      await this.ensureBucketExists();

      // Extract mime type and base64 data
      const matches = picture.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
      if (!matches || matches.length !== 3) {
        return picture;
      }

      const contentType = matches[1];
      const base64Data = matches[2];
      const buffer = Buffer.from(base64Data, 'base64');

      const ext = contentType.includes('png')
        ? 'png'
        : contentType.includes('webp')
        ? 'webp'
        : 'jpg';
      const fileName = `${userId}/${Date.now()}.${ext}`;

      const { data, error } = await this.supabase.storage
        .from(this.bucketName)
        .upload(fileName, buffer, {
          contentType,
          upsert: true,
        });

      if (error) {
        this.logger.warn(
          `Supabase storage upload failed: ${error.message}. Storing in DB directly.`,
        );
        return picture;
      }

      const { data: publicData } = this.supabase.storage
        .from(this.bucketName)
        .getPublicUrl(data.path);

      return publicData.publicUrl;
    } catch (err) {
      this.logger.warn(
        `Error processing avatar in storage: ${(err as Error).message}. Storing in DB directly.`,
      );
      return picture;
    }
  }

  /**
   * Deletes the one uploaded picture `url` links to, when it is a file in the person's folder
   * (`<userId>/` in the bucket); presets, data URIs and other links are left alone. Used for the
   * picture a change replaced: deleting only that file never touches the upload of another save
   * still in progress. Failures are logged and never thrown.
   */
  async removeAvatar(userId: string, url: string | null | undefined): Promise<void> {
    if (!this.supabase || !url) return;

    const folder = `${this.bucketName}/${userId}/`;
    if (!url.includes(folder)) return;
    const name = url.slice(url.indexOf(folder) + folder.length).split('?')[0];
    if (!name || name.includes('/')) return;

    try {
      const { error } = await this.supabase.storage
        .from(this.bucketName)
        .remove([`${userId}/${name}`]);
      if (error) throw error;
    } catch (err) {
      this.logger.warn(
        `Could not delete an old picture of user ${userId}: ${(err as Error).message}`,
      );
    }
  }

  /**
   * Deletes every uploaded picture of the person (`<userId>/` in the bucket), once the account
   * is deleted. Failures are logged and never thrown.
   */
  async removeAvatars(userId: string): Promise<void> {
    if (!this.supabase) return;

    const bucket = this.supabase.storage.from(this.bucketName);

    try {
      // Removing a page of names brings the next ones to the first page.
      for (let page = 0; page < MAX_AVATAR_PAGES; page++) {
        const { data, error } = await bucket.list(userId, { limit: AVATAR_PAGE_SIZE });
        if (error) throw error;
        const paths = data.map((file) => `${userId}/${file.name}`);
        if (paths.length === 0) return;
        const { error: removeError } = await bucket.remove(paths);
        if (removeError) throw removeError;
        if (data.length < AVATAR_PAGE_SIZE) return;
      }
    } catch (err) {
      this.logger.warn(
        `Could not delete old pictures of user ${userId}: ${(err as Error).message}`,
      );
    }
  }
}
