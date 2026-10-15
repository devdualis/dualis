import { Module } from '@nestjs/common';
import { ProfilesModule } from '../profiles/profiles.module';
import { TriageAuditController } from './triage-audit.controller';
import { TriageAuditService } from './triage-audit.service';

@Module({
  imports: [ProfilesModule],
  controllers: [TriageAuditController],
  providers: [TriageAuditService],
  exports: [TriageAuditService],
})
export class TriageAuditModule {}
