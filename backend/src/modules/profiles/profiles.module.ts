import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { ProfilesController } from './profiles.controller';
import { ProfilesService } from './profiles.service';
import { FamilySharingController } from './family-sharing.controller';
import { FamilySharingService } from './family-sharing.service';
import { ProfileContextGuard } from './profile-context';

@Module({
  imports: [DatabaseModule],
  controllers: [ProfilesController, FamilySharingController],
  providers: [ProfilesService, FamilySharingService, ProfileContextGuard],
  exports: [ProfilesService, FamilySharingService, ProfileContextGuard],
})
export class ProfilesModule {}
