import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { Logger } from '@nestjs/common';
import { EmailService } from '../../src/common/email/email.service';
import { findBannedVocabulary } from '../../scripts/banned-vocabulary';

describe('EmailService (Resend)', () => {
  const originalEnv = { ...process.env };
  let fetchMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    process.env.NODE_ENV = 'development';
    process.env.RESEND_API_KEY = 're_test_key';
    process.env.MAIL_FROM = 'DualisCheckUp <nao-responda@dualischeckup.com>';
    fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify({ id: 'email-1' }), { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('sends the verification email through the Resend API', async () => {
    await new EmailService().sendVerificationEmail(' Maria@Example.com ', '123456', 'Maria Santos');

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('https://api.resend.com/emails');
    expect(init.method).toBe('POST');
    expect(init.headers.Authorization).toBe('Bearer re_test_key');
    const body = JSON.parse(init.body);
    expect(body.from).toBe('DualisCheckUp <nao-responda@dualischeckup.com>');
    expect(body.to).toEqual(['maria@example.com']);
    expect(body.subject).toContain('123456');
    expect(body.text).toContain('Maria');
    expect(body.html).toContain('123456');
  });

  it('sends the password reset email through the Resend API', async () => {
    await new EmailService().sendPasswordResetEmail('joao@example.com', '654321');

    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.to).toEqual(['joao@example.com']);
    expect(body.subject).toContain('redefinição de senha');
    expect(body.html).toContain('654321');
  });

  it('escapes the name in the HTML and keeps the copy free of banned vocabulary', async () => {
    const service = new EmailService();
    await service.sendVerificationEmail('ana@example.com', '123456', '<b>Ana</b>');
    await service.sendPasswordResetEmail('ana@example.com', '654321');

    expect(JSON.parse(fetchMock.mock.calls[0][1].body).html).toContain('&#60;b&#62;Ana');
    for (const [, init] of fetchMock.mock.calls) {
      const body = JSON.parse(init.body);
      expect(body.html).not.toContain('<b>Ana');
      expect(findBannedVocabulary(`${body.subject}\n${body.text}\n${body.html}`)).toEqual([]);
    }
  });

  it('does not call Resend without an API key and keeps the code in memory', async () => {
    delete process.env.RESEND_API_KEY;
    const service = new EmailService();

    await service.sendVerificationEmail('ana@example.com', '111222');

    expect(fetchMock).not.toHaveBeenCalled();
    expect(service.getLastSentCode('ana@example.com')).toBe('111222');
  });

  it('does not call Resend when NODE_ENV is test', async () => {
    process.env.NODE_ENV = 'test';

    await new EmailService().sendVerificationEmail('ana@example.com', '111222');

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('logs a Resend rejection without the code and does not throw', async () => {
    fetchMock.mockResolvedValue(
      new Response(JSON.stringify({ name: 'validation_error', message: 'Domain not verified' }), { status: 403 }),
    );
    const errorSpy = vi.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);

    await expect(new EmailService().sendVerificationEmail('ana@example.com', '987654')).resolves.toBeUndefined();

    const logged = errorSpy.mock.calls.map((args) => String(args[0])).join('\n');
    expect(logged).toContain('403');
    expect(logged).not.toContain('987654');
  });

  it('does not throw when the request fails', async () => {
    fetchMock.mockRejectedValue(new Error('network down'));
    vi.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);

    await expect(new EmailService().sendPasswordResetEmail('ana@example.com', '987654')).resolves.toBeUndefined();
  });
});
