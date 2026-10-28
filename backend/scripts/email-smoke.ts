/**
 * Live smoke test for Resend. Reads RESEND_API_KEY / MAIL_FROM from the backend env file,
 * lists the account's sending domains and sends one test verification email.
 * Prints only results, never the key. Run: npx tsx scripts/email-smoke.ts you@example.com
 */
import 'dotenv/config';
import { EmailService } from '../src/common/email/email.service';

async function main() {
  const to = process.argv[2];
  if (!to) throw new Error('Usage: npx tsx scripts/email-smoke.ts you@example.com');
  if (!process.env.RESEND_API_KEY) throw new Error('RESEND_API_KEY missing');
  console.log('from:', process.env.MAIL_FROM || '(default)');

  // Sending-only keys cannot list domains (401); that is fine.
  const res = await fetch('https://api.resend.com/domains', {
    headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}` },
  });
  if (res.ok) {
    const { data } = (await res.json()) as { data: { name: string; status: string; region: string }[] };
    console.log('domains:', data.map((d) => `${d.name} ${d.status} ${d.region}`).join(', ') || 'none');
  } else {
    console.log('domains: not listed (HTTP', res.status, ')');
  }

  const email = new EmailService();
  await email.sendVerificationEmail(to, email.generateVerificationCode(), 'Teste');
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
