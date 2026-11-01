import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { ProfilesModule } from '../profiles/profiles.module';
import { HabitsController } from './habits.controller';
import { HabitsService } from './habits.service';

@Module({
  imports: [DatabaseModule, ProfilesModule],
  controllers: [HabitsController],
  providers: [HabitsService],
  exports: [HabitsService],
})
export class HabitsModule {}
