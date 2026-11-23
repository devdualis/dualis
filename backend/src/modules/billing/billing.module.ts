import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';
import { ConditionPremiumGuard, PremiumGuard } from './premium.guard';

@Module({ imports: [DatabaseModule], controllers: [BillingController], providers: [BillingService, PremiumGuard, ConditionPremiumGuard], exports: [BillingService, PremiumGuard, ConditionPremiumGuard] })
export class BillingModule {}
