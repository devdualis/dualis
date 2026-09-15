import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

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

      this.logger.log(
        `Uploaded avatar for user ${userId} to Supabase Storage: ${publicData.publicUrl}`,
      );
      return publicData.publicUrl;
    } catch (err) {
      this.logger.warn(
        `Error processing avatar in storage: ${(err as Error).message}. Storing in DB directly.`,
      );
      return picture;
    }
  }
}
