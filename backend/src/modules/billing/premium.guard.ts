import { CanActivate, ExecutionContext, Inject, Injectable } from '@nestjs/common';
import { BillingService } from './billing.service';

@Injectable()
export class PremiumGuard implements CanActivate {
  constructor(@Inject(BillingService) private readonly billing: BillingService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    await this.billing.requirePremium(context.switchToHttp().getRequest().user?.id);
    return true;
  }
}

/** Conditions themselves and ordinary journal entries stay free. Only turning
 * on measurement tracking or adding measurements consumes a paid capability. */
@Injectable()
export class ConditionPremiumGuard implements CanActivate {
  constructor(@Inject(BillingService) private readonly billing: BillingService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const body = req.body;
    const tracking = Array.isArray(body?.tracking) && body.tracking.length > 0;
    const readings = Array.isArray(body?.items) && body.items.some((item: any) =>
      Array.isArray(item?.readings) && item.readings.length > 0,
    );
    if (tracking || readings) await this.billing.requirePremium(req.user?.id);
    return true;
  }
}
