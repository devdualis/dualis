import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

const RESEND_API_URL = 'https://api.resend.com/emails';
const SEND_TIMEOUT_MS = 10_000;

// The name is user input; escape it so nobody can inject links or markup into
// an email sent from our domain.
function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly apiKey: string | undefined;
  private readonly mailFrom: string;
  private readonly sentCodesMemory = new Map<string, { code: string; sentAt: Date }>();

  constructor(@Optional() private readonly configService?: ConfigService) {
    this.apiKey = this.configService?.get<string>('RESEND_API_KEY') || process.env.RESEND_API_KEY;
    // The sender domain must be verified in Resend.
    this.mailFrom =
      this.configService?.get<string>('MAIL_FROM') ||
      process.env.MAIL_FROM ||
      'DualisCheckUp <nao-responda@dualischeckup.com>';

    if (this.apiKey) {
      this.logger.log('[EmailService] Envio de e-mails via Resend');
    } else if (process.env.NODE_ENV === 'production') {
      this.logger.error('[EmailService] RESEND_API_KEY ausente em produção: nenhum e-mail será enviado.');
    } else {
      this.logger.warn('[EmailService] RESEND_API_KEY ausente. Operando em modo de simulação (memória e console).');
    }
  }

  // Codes and addresses only reach the logs in simulation mode (no API key, not
  // production); otherwise anyone with log access could take over an account.
  private logCodeForSimulation(kind: string, email: string, code: string) {
    if (this.apiKey || process.env.NODE_ENV === 'production') return;
    this.logger.log(`[EmailService] Simulação: código de ${kind} para ${email}: [${code}]`);
  }

  // Failures are logged, never thrown: the code hash is already stored and the
  // user can ask for a new code. Logs never include the code.
  private async deliver(to: string, subject: string, text: string, html: string): Promise<void> {
    if (!this.apiKey || process.env.NODE_ENV === 'test') return;

    try {
      const res = await fetch(RESEND_API_URL, {
        method: 'POST',
        headers: { Authorization: `Bearer ${this.apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ from: this.mailFrom, to: [to], subject, text, html }),
        signal: AbortSignal.timeout(SEND_TIMEOUT_MS),
      });
      if (!res.ok) {
        const body = await res.text().catch(() => '');
        this.logger.error(`[EmailService] Resend recusou o envio (${res.status}): ${body.slice(0, 300)}`);
        return;
      }
      const { id } = (await res.json().catch(() => ({}))) as { id?: string };
      this.logger.log(`[EmailService] E-mail enviado via Resend (id ${id ?? 'desconhecido'})`);
    } catch (err: any) {
      this.logger.error(`[EmailService] Falha ao enviar via Resend: ${err.message}`, err.stack);
    }
  }

  generateVerificationCode(): string {
    return crypto.randomInt(100000, 1000000).toString();
  }

  hashCode(code: string): string {
    return crypto.createHash('sha256').update(code.trim()).digest('hex');
  }

  verifyCodeHash(code: string, codeHash: string): boolean {
    const computed = this.hashCode(code);
    return crypto.timingSafeEqual(Buffer.from(computed), Buffer.from(codeHash));
  }

  async sendVerificationEmail(to: string, code: string, name?: string): Promise<void> {
    const normalizedEmail = to.toLowerCase().trim();
    this.sentCodesMemory.set(normalizedEmail, { code, sentAt: new Date() });

    const firstName = name?.trim().split(' ')[0];
    this.logCodeForSimulation('verificação', normalizedEmail, code);

    const htmlContent = `
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #F8FAFC; color: #1E293B; margin: 0; padding: 20px; }
          .container { max-width: 520px; margin: 0 auto; background: #FFFFFF; border-radius: 16px; padding: 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border: 1px solid #E2E8F0; }
          .header { text-align: center; margin-bottom: 24px; }
          .title { font-size: 24px; font-weight: bold; color: #00796B; margin: 0; }
          .subtitle { font-size: 14px; color: #64748B; margin-top: 4px; }
          .content { font-size: 16px; line-height: 1.6; color: #334155; margin-bottom: 24px; }
          .code-box { background-color: #F0FDFA; border: 2px dashed #00796B; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0; }
          .code { font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #00796B; font-family: monospace; }
          .footer { font-size: 12px; color: #94A3B8; text-align: center; border-top: 1px solid #E2E8F0; padding-top: 16px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 class="title">DualisCheckUp</h1>
            <p class="subtitle">Seu diário de bem-estar</p>
          </div>
          <div class="content">
            <p>Olá${firstName ? `, <strong>${escapeHtml(firstName)}</strong>` : ''},</p>
            <p>Obrigado por criar sua conta no <strong>DualisCheckUp</strong>. Para confirmar que este endereço de e-mail é seu e ativar sua conta com segurança, utilize o código de verificação abaixo:</p>
            <div class="code-box">
              <span class="code">${code}</span>
            </div>
            <p>Este código expira em <strong>15 minutos</strong>. Se você não solicitou este cadastro, ignore esta mensagem com segurança.</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 DualisCheckUp. Em conformidade com a LGPD (Lei nº 13.709/2018).</p>
          </div>
        </div>
      </body>
      </html>
    `;

    await this.deliver(
      normalizedEmail,
      `${code} é seu código de verificação DualisCheckUp`,
      `Olá${firstName ? ` ${firstName}` : ''}, seu código de verificação do DualisCheckUp é: ${code}. Ele expira em 15 minutos.`,
      htmlContent,
    );
  }

  getLastSentCode(email: string): string | undefined {
    return this.sentCodesMemory.get(email.toLowerCase().trim())?.code;
  }

  async sendPasswordResetEmail(to: string, code: string, name?: string): Promise<void> {
    const normalizedEmail = to.toLowerCase().trim();
    this.sentCodesMemory.set(normalizedEmail, { code, sentAt: new Date() });

    const firstName = name?.trim().split(' ')[0];
    this.logCodeForSimulation('redefinição de senha', normalizedEmail, code);

    const htmlContent = `
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #F8FAFC; color: #1E293B; margin: 0; padding: 20px; }
          .container { max-width: 520px; margin: 0 auto; background: #FFFFFF; border-radius: 16px; padding: 32px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); border: 1px solid #E2E8F0; }
          .header { text-align: center; margin-bottom: 24px; }
          .title { font-size: 24px; font-weight: bold; color: #00796B; margin: 0; }
          .subtitle { font-size: 14px; color: #64748B; margin-top: 4px; }
          .content { font-size: 16px; line-height: 1.6; color: #334155; margin-bottom: 24px; }
          .code-box { background-color: #F0FDFA; border: 2px dashed #00796B; border-radius: 12px; padding: 18px; text-align: center; margin: 24px 0; }
          .code { font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #00796B; font-family: monospace; }
          .footer { font-size: 12px; color: #94A3B8; text-align: center; border-top: 1px solid #E2E8F0; padding-top: 16px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1 class="title">DualisCheckUp</h1>
            <p class="subtitle">Seu diário de bem-estar</p>
          </div>
          <div class="content">
            <p>Olá${firstName ? `, <strong>${escapeHtml(firstName)}</strong>` : ''},</p>
            <p>Recebemos uma solicitação para redefinir a senha da sua conta no <strong>DualisCheckUp</strong>. Utilize o código abaixo para criar uma nova senha:</p>
            <div class="code-box">
              <span class="code">${code}</span>
            </div>
            <p>Este código expira em <strong>15 minutos</strong>. Se você não solicitou a redefinição de senha, ignore esta mensagem com segurança; sua senha atual continuará válida.</p>
          </div>
          <div class="footer">
            <p>&copy; 2026 DualisCheckUp. Em conformidade com a LGPD (Lei nº 13.709/2018).</p>
          </div>
        </div>
      </body>
      </html>
    `;

    await this.deliver(
      normalizedEmail,
      `${code} é seu código de redefinição de senha DualisCheckUp`,
      `Olá${firstName ? ` ${firstName}` : ''}, seu código de redefinição de senha do DualisCheckUp é: ${code}. Ele expira em 15 minutos. Se você não solicitou, ignore esta mensagem.`,
      htmlContent,
    );
  }
}
