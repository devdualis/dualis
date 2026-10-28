import { describe, it, expect, beforeEach } from 'vitest';
import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import {
  LegalService,
  LEGAL_DOCUMENTS_VERSION,
  INTENDED_USE_STATEMENT,
} from '../../src/modules/legal/legal.service';

// Terms that would describe the product as a medical device / triage tool (plan §2, L-01..L-07).
const BANNED_LEGAL_TERMS =
  /RDC|657\/2022|CFM|2\.314|SaMD|estratifica|stratification|triag|triaj|protocolos? cl[ií]nicos|clinical protocols|aut[oô]nom|autonomous|Art\. 11, II|PCI-DSS|prontu[aá]rio/i;

describe('LegalService - SaaS Legal Foundations', () => {
  let service: LegalService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LegalService,
        {
          provide: ConfigService,
          useValue: {
            get: (key: string) => {
              if (key === 'TERMS_VERSION') return '2026.2';
              if (key === 'PRIVACY_VERSION') return '2026.2';
              if (key === 'SECURITY_VERSION') return '2026.2';
              return null;
            },
          },
        },
      ],
    }).compile();

    service = module.get<LegalService>(LegalService);
  });

  it('should return clear legal entity details (Video 2 - Requisito 1: Estructura Legal)', () => {
    const entity = service.getLegalEntityDetails();
    expect(entity.companyName).toBe('WGI (Brothers Baum Ltda.)');
    expect(entity.taxId).toBe('30.889.282/0001-90');
    expect(entity.legalEmail).toBe('contato@dualischeckup.com');
    expect(entity.dpoEmail).toBe('contato@dualischeckup.com');
    expect(entity.supportEmail).toBe('contato@dualischeckup.com');
  });

  describe('Terms of Service (Video 2 - Requisito 2: Términos de Uso)', () => {
    it('should return complete Portuguese SaaS terms with CDC refund rights', () => {
      const terms = service.getTermsOfService('pt-BR');
      expect(terms.language).toBe('pt-BR');
      expect(terms.title).toContain('Termos e Condições de Uso');
      expect(terms.sections.length).toBeGreaterThanOrEqual(5);

      const refundSection = terms.sections.find((s) => s.sectionId === '3-pagamentos-cancelamento-reembolso');
      expect(refundSection).toBeDefined();
      expect(refundSection?.bullets?.some((b) => b.includes('CDC') && b.includes('7 (sete) dias'))).toBe(true);
    });

    it('should return Spanish and English versions based on query or headers', () => {
      const termsEs = service.getTermsOfService('es');
      expect(termsEs.language).toBe('es');
      expect(termsEs.title).toContain('Términos y Condiciones');

      const termsEn = service.getTermsOfService(undefined, 'en-US,en;q=0.9');
      expect(termsEn.language).toBe('en');
      expect(termsEn.title).toContain('Terms of Service');
    });
  });

  describe('Privacy Policy (Video 2 - Requisito 3: Políticas de Privacidad)', () => {
    it('should return LGPD/GDPR privacy policy with explicit rights and DPO contact', () => {
      const privacy = service.getPrivacyPolicy('pt-BR');
      expect(privacy.language).toBe('pt-BR');
      expect(privacy.lgpdCompliance.sensitiveDataArticle).toContain('Artigo 11');
      expect(privacy.lgpdCompliance.dpoContact).toBe('contato@dualischeckup.com');
      expect(privacy.lgpdCompliance.rights.length).toBeGreaterThan(3);

      const paymentSec = privacy.sections.find((s) => s.sectionId === '4-pagamentos');
      expect(paymentSec).toBeDefined();
      expect(paymentSec?.content).toContain('NUNCA');
      expect(paymentSec?.content).not.toContain('PCI-DSS');
    });
  });

  describe('Security & Incident Response (Video 2 - Requisito 4: Seguridad)', () => {
    it('should detail Argon2id, RLS isolation, TLS 1.3, and 72h ANPD breach notification', () => {
      const security = service.getSecurityPolicy('pt-BR');
      expect(security.passwordHashing).toContain('Argon2id');
      expect(security.tenantIsolation).toContain('Row-Level Security');
      expect(security.incidentResponsePlan.breachNotificationWindowHours).toBe(72);
      expect(security.incidentResponsePlan.regulatoryNotificationBody).toContain('ANPD');
    });
  });

  describe('Wellness intended use (plan F1)', () => {
    const langs = ['pt-BR', 'en', 'es'] as const;

    it.each(langs)('legal texts in %s contain no medical-device or triage claims', (lang) => {
      const docs = [
        service.getTermsOfService(lang),
        service.getPrivacyPolicy(lang),
        service.getMedicalDisclaimer(lang),
      ];
      const serialized = JSON.stringify(docs);
      expect(serialized).not.toMatch(BANNED_LEGAL_TERMS);
    });

    it.each(langs)('terms section 2 "Nature of the Service" is the canonical intended-use statement (%s)', (lang) => {
      const terms = service.getTermsOfService(lang);
      const section2 = terms.sections.find((s) => s.sectionId.startsWith('2-'));
      expect(section2?.content).toBe(INTENDED_USE_STATEMENT[lang]);
    });

    it('pt-BR terms section is titled "2. Natureza do Serviço"', () => {
      const terms = service.getTermsOfService('pt-BR');
      expect(terms.sections[1].title).toBe('2. Natureza do Serviço');
    });

    it.each(langs)('privacy policy uses LGPD Art. 11, I consent, discloses AI for diary chips, and Art. 33 (%s)', (lang) => {
      const privacy = service.getPrivacyPolicy(lang);
      expect(privacy.lgpdCompliance.legalBases[0]).toContain('Art. 11, I');
      expect(privacy.lgpdCompliance.legalBases.join(' ')).not.toMatch(/VIII/);
      const serialized = JSON.stringify(privacy.sections);
      expect(serialized).toMatch(/provedor de IA|proveedor de IA|AI provider/);
      expect(serialized).not.toMatch(/organizarlas automáticamente por área|body area or mood/i);
      expect(serialized).toContain('Art. 33');
    });

    it.each(langs)('privacy policy describes processors by category, never by provider name (%s)', (lang) => {
      const privacy = service.getPrivacyPolicy(lang);
      const section3 = privacy.sections.find((s) => s.sectionId.startsWith('3-'));
      expect(section3?.bullets).toHaveLength(6);
      const serialized = JSON.stringify(privacy.sections);
      expect(serialized).not.toMatch(/Google|Gemini|Vertex|Vision|Resend|Supabase/);
      expect(serialized).toContain('Art. 18, VII');
    });
  });

  describe('Disclaimer & Emergency Contacts', () => {
    it('returns the intended-use statement, LGPD/CDC citations only, and help numbers', () => {
      const disclaimer = service.getMedicalDisclaimer('pt-BR');
      expect(disclaimer.disclaimerText).toBe(INTENDED_USE_STATEMENT['pt-BR']);
      expect(disclaimer.citations.map((c) => c.normativeAct).join(' ')).toMatch(/LGPD/);
      expect(disclaimer.citations.some((c) => /Anvisa|SaMD|CFM/.test(c.regulatoryBody))).toBe(false);
      expect(disclaimer.emergencyContacts.some((c) => c.phone === '192')).toBe(true);
      expect(disclaimer.emergencyContacts.some((c) => c.phone === '188')).toBe(true);
    });

    it('defaults the disclaimer version to the bumped 2026.3 so every user re-consents', () => {
      expect(LEGAL_DOCUMENTS_VERSION).toBe('2026.3');
      expect(service.getMedicalDisclaimer('pt-BR').version).toBe('2026.3');
    });
  });
});
