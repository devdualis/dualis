import { EMAIL_LOGO_PNG_BASE64 } from './email-logo';

const LOGO_CID = 'dualis-logo';

// Resend inline attachment: the HTML shows it through `cid:`, so the logo needs no public hosting
// and is not blocked like a remote image.
export const EMAIL_LOGO_ATTACHMENT = {
  filename: 'dualis-logo.png',
  content: EMAIL_LOGO_PNG_BASE64,
  content_type: 'image/png',
  content_id: LOGO_CID,
};

// The name is user input; escape it so nobody can inject links or markup into
// an email sent from our domain.
export function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
}

export interface CodeEmailContent {
  /** Inbox preview line, hidden in the body. */
  preheader: string;
  title: string;
  firstName?: string;
  /** Trusted HTML (our own copy). */
  intro: string;
  code: string;
  /** Trusted HTML (our own copy). */
  ignoreNote: string;
}

// Email clients ignore most CSS, so the layout uses tables and inline styles only.
// Colors and logo size follow docs/dualis_brand_guidelines.md (logo at least 150 px wide).
const FONT = "Inter, 'Helvetica Neue', Helvetica, Arial, sans-serif";
const MONO = "'SF Mono', Menlo, Consolas, 'Courier New', monospace";

export function renderCodeEmail(email: CodeEmailContent): string {
  const greeting = email.firstName ? `Olá, <strong>${escapeHtml(email.firstName)}</strong>!` : 'Olá!';
  const year = new Date().getFullYear();

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>${email.title}</title>
</head>
<body style="margin:0;padding:0;background-color:#F0F7FB;-webkit-text-size-adjust:100%;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;mso-hide:all;">${email.preheader}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F0F7FB;">
<tr><td align="center" style="padding:32px 12px;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;background-color:#FFFFFF;border:1px solid #DCEAF3;border-radius:16px;border-collapse:separate;overflow:hidden;">
    <tr>
      <td width="34%" height="6" style="height:6px;line-height:6px;font-size:0;background-color:#0B83C9;">&nbsp;</td>
      <td width="33%" height="6" style="height:6px;line-height:6px;font-size:0;background-color:#26B7D7;">&nbsp;</td>
      <td width="33%" height="6" style="height:6px;line-height:6px;font-size:0;background-color:#66BE71;">&nbsp;</td>
    </tr>
    <tr><td colspan="3" align="center" style="padding:36px 32px 4px;">
      <img src="cid:${LOGO_CID}" width="200" height="48" alt="Dualis — continuous check up" style="display:block;width:200px;height:48px;border:0;outline:none;text-decoration:none;font-family:${FONT};font-size:20px;font-weight:600;color:#0E3E6C;">
    </td></tr>
    <tr><td colspan="3" style="padding:28px 32px 0;font-family:${FONT};">
      <h1 style="margin:0 0 16px;font-size:22px;line-height:30px;font-weight:600;color:#0E3E6C;">${email.title}</h1>
      <p style="margin:0 0 12px;font-size:16px;line-height:24px;color:#334155;">${greeting}</p>
      <p style="margin:0;font-size:16px;line-height:24px;color:#334155;">${email.intro}</p>
    </td></tr>
    <tr><td colspan="3" style="padding:24px 32px 0;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F0F7FB;border:1px solid #CFE6F3;border-radius:12px;border-collapse:separate;">
        <tr><td align="center" style="padding:20px 12px 22px;font-family:${FONT};">
          <p style="margin:0 0 6px;font-size:12px;line-height:16px;letter-spacing:1.5px;text-transform:uppercase;font-weight:600;color:#2B9ED0;">Seu código</p>
          <p style="margin:0;padding-left:10px;font-family:${MONO};font-size:36px;line-height:44px;letter-spacing:10px;font-weight:700;color:#0E3E6C;">${email.code}</p>
          <p style="margin:8px 0 0;font-size:13px;line-height:18px;color:#64748B;">Válido por 15 minutos</p>
        </td></tr>
      </table>
    </td></tr>
    <tr><td colspan="3" style="padding:24px 32px 32px;font-family:${FONT};">
      <p style="margin:0;font-size:14px;line-height:22px;color:#64748B;">${email.ignoreNote}</p>
    </td></tr>
    <tr><td colspan="3" style="padding:16px 32px;background-color:#F8FAFC;border-top:1px solid #E2E8F0;font-family:${FONT};">
      <p style="margin:0;font-size:13px;line-height:20px;color:#475569;">Em emergência, ligue <a href="tel:192" style="color:#0E3E6C;font-weight:600;text-decoration:none;white-space:nowrap;">192 (SAMU)</a>. Se você estiver em sofrimento emocional, ligue <a href="tel:188" style="color:#0E3E6C;font-weight:600;text-decoration:none;white-space:nowrap;">188 (CVV)</a>.</p>
    </td></tr>
  </table>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;">
    <tr><td align="center" style="padding:20px 24px 0;font-family:${FONT};font-size:12px;line-height:18px;color:#94A3B8;">
      Mensagem automática do Dualis CheckUp, seu diário de <span style="white-space:nowrap;">bem-estar</span>.<br>
      Não responda a este e-mail.<br>
      Dúvidas: <a href="mailto:contato@dualischeckup.com" style="color:#64748B;text-decoration:underline;">contato@dualischeckup.com</a><br>
      &copy; ${year} Dualis CheckUp · Em conformidade com a LGPD (Lei nº 13.709/2018)
    </td></tr>
  </table>
</td></tr>
</table>
</body>
</html>`;
}
