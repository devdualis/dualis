import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { LegalService } from '../../src/modules/legal/legal.service';

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
              if (key === 'TERMS_VERSION') return '2026.1';
              if (key === 'PRIVACY_VERSION') return '2026.1';
              if (key === 'SECURITY_VERSION') return '2026.1';
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
    expect(entity.companyName).toBe('DualisCheckUp Saúde e Tecnologia Ltda.');
    expect(entity.taxId).toBe('48.291.834/0001-92');
    expect(entity.legalEmail).toBe('legal@dualischeckup.com');
    expect(entity.dpoEmail).toBe('dpo@dualischeckup.com');
    expect(entity.supportEmail).toBe('suporte@dualischeckup.com');
  });

  describe('Terms of Service (Video 2 - Requisito 2: Términos de Uso)', () => {
    it('should return complete Portuguese SaaS terms with CDC refund rights & medical disclaimers', () => {
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
      expect(privacy.lgpdCompliance.dpoContact).toBe('dpo@dualischeckup.com');
      expect(privacy.lgpdCompliance.rights.length).toBeGreaterThan(3);

      const paymentSec = privacy.sections.find((s) => s.sectionId === '3-pagamentos-e-pci');
      expect(paymentSec).toBeDefined();
      expect(paymentSec?.content).toContain('PCI-DSS');
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

  describe('Medical Disclaimer & Emergency Protocol', () => {
    it('should preserve existing clinical disclaimer with Anvisa and CFM citations', () => {
      const disclaimer = service.getMedicalDisclaimer('pt-BR');
      expect(disclaimer.citations.some((c) => c.regulatoryBody.includes('Anvisa'))).toBe(true);
      expect(disclaimer.emergencyContacts.some((c) => c.phone === '192')).toBe(true);
    });
  });
});
