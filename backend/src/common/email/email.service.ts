import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { EMAIL_LOGO_ATTACHMENT, renderCodeEmail } from './email-template';

const RESEND_API_URL = 'https://api.resend.com/emails';
const SEND_TIMEOUT_MS = 10_000;

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
        body: JSON.stringify({ from: this.mailFrom, to: [to], subject, text, html, attachments: [EMAIL_LOGO_ATTACHMENT] }),
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

    const htmlContent = renderCodeEmail({
      preheader: `Seu código de verificação é ${code}. Ele expira em 15 minutos.`,
      title: 'Confirme seu e-mail',
      firstName,
      intro:
        'Obrigado por criar sua conta no <strong>DualisCheckUp</strong>. Para confirmar que este endereço de e-mail é seu e ativar sua conta com segurança, use o código abaixo:',
      code,
      ignoreNote: 'Se você não solicitou este cadastro, ignore esta mensagem com segurança.',
    });

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

    const htmlContent = renderCodeEmail({
      preheader: `Seu código de redefinição de senha é ${code}. Ele expira em 15 minutos.`,
      title: 'Redefina sua senha',
      firstName,
      intro:
        'Recebemos uma solicitação para redefinir a senha da sua conta no <strong>DualisCheckUp</strong>. Use o código abaixo para criar uma nova senha:',
      code,
      ignoreNote:
        'Se você não solicitou a redefinição de senha, ignore esta mensagem com segurança; sua senha atual continuará válida.',
    });

    await this.deliver(
      normalizedEmail,
      `${code} é seu código de redefinição de senha DualisCheckUp`,
      `Olá${firstName ? ` ${firstName}` : ''}, seu código de redefinição de senha do DualisCheckUp é: ${code}. Ele expira em 15 minutos. Se você não solicitou, ignore esta mensagem.`,
      htmlContent,
    );
  }
}
