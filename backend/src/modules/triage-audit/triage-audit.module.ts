import { Module } from '@nestjs/common';
import { TriageAuditController } from './triage-audit.controller';
import { TriageAuditService } from './triage-audit.service';

@Module({
  controllers: [TriageAuditController],
  providers: [TriageAuditService],
  exports: [TriageAuditService],
})
export class TriageAuditModule {}
