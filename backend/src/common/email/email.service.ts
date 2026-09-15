import { Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;
  private readonly sentCodesMemory = new Map<string, { code: string; sentAt: Date }>();

  constructor(@Optional() private readonly configService?: ConfigService) {
    this.initTransporter();
  }

  private initTransporter() {
    const host = this.configService?.get<string>('SMTP_HOST') || process.env.SMTP_HOST;
    const port = parseInt(this.configService?.get<string>('SMTP_PORT') || process.env.SMTP_PORT || '587', 10);
    const user = this.configService?.get<string>('SMTP_USER') || process.env.SMTP_USER;
    const pass = this.configService?.get<string>('SMTP_PASS') || process.env.SMTP_PASS;

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: {
          user,
          pass,
        },
      });
      this.logger.log(`[EmailService] Transporter SMTP configurado para ${host}:${port}`);
    } else {
      this.logger.warn(
        '[EmailService] Credenciais SMTP incompletas. Operando em modo de simulação (memória e console).',
      );
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

    const recipientName = name ? name.split(' ')[0] : 'Paciente';
    const mailFrom =
      this.configService?.get<string>('MAIL_FROM') ||
      process.env.MAIL_FROM ||
      'DualisCheckUp <dev@wgi.one>';

    this.logger.log(
      `[EmailService] Preparando envio de verificação para ${normalizedEmail}: [${code}] (Destinatário: ${recipientName})`,
    );

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
            <p class="subtitle">Triagem Preventiva e Histórico Clínico Unificado</p>
          </div>
          <div class="content">
            <p>Olá, <strong>${recipientName}</strong>,</p>
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

    if (this.transporter && process.env.NODE_ENV !== 'test') {
      try {
        await this.transporter.sendMail({
          from: mailFrom,
          to: normalizedEmail,
          subject: `${code} é seu código de verificação DualisCheckUp`,
          text: `Olá ${recipientName}, seu código de verificação do DualisCheckUp é: ${code}. Ele expira em 15 minutos.`,
          html: htmlContent,
        });
        this.logger.log(`[EmailService] E-mail SMTP enviado com sucesso para ${normalizedEmail}`);
      } catch (err: any) {
        this.logger.error(`[EmailService] Falha ao enviar via SMTP: ${err.message}`, err.stack);
        // Fallback: don't crash app if SMTP fails, code is logged for emergency access
      }
    }
  }

  getLastSentCode(email: string): string | undefined {
    return this.sentCodesMemory.get(email.toLowerCase().trim())?.code;
  }
}
