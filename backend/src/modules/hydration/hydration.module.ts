import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { HydrationController } from './hydration.controller';
import { HydrationService } from './hydration.service';

@Module({
  imports: [DatabaseModule],
  controllers: [HydrationController],
  providers: [HydrationService],
  exports: [HydrationService],
})
export class HydrationModule {}
