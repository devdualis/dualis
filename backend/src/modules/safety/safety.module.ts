import { Module } from '@nestjs/common';
import { RateLimiter } from '../../common/http/rate-limiter';
import { ProfilesModule } from '../profiles/profiles.module';
import { SafetyEventsController } from './safety-events.controller';
import { SafetyEventsService } from './safety-events.service';

@Module({
  imports: [ProfilesModule],
  controllers: [SafetyEventsController],
  providers: [SafetyEventsService, RateLimiter],
  exports: [SafetyEventsService],
})
export class SafetyModule {}
