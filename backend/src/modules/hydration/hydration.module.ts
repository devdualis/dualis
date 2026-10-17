import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { ProfilesModule } from '../profiles/profiles.module';
import { HydrationController } from './hydration.controller';
import { HydrationService } from './hydration.service';

@Module({
  imports: [DatabaseModule, ProfilesModule],
  controllers: [HydrationController],
  providers: [HydrationService],
  exports: [HydrationService],
})
export class HydrationModule {}
