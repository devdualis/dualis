import { Body, Controller, Get, Headers, HttpCode, Inject, Post, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { BillingService } from './billing.service';

@Controller({ path: 'billing', version: '1' })
export class BillingController {
  constructor(@Inject(BillingService) private readonly billing: BillingService) {}

  @Get('subscription')
  @UseGuards(JwtAuthGuard)
  status(@Request() req: any) { return this.billing.getSubscription(req.user.id); }

  @Post('sync')
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  sync(@Request() req: any) { return this.billing.sync(req.user.id); }

  @Post('webhooks/revenuecat')
  @HttpCode(200)
  webhook(@Headers('authorization') authorization: string | undefined, @Body() body: unknown) {
    return this.billing.webhook(authorization, body);
  }
}
