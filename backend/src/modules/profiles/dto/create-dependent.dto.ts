import { Equals, IsIn, IsISO8601, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { RELATIONSHIP_TYPES, RelationshipType } from '../../../database/schema/legal-guardianships.schema';

export const PROFILE_GENDERS = ['masculino', 'feminino', 'outro'] as const;

export class CreateDependentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(255)
  name!: string;

  @IsISO8601(
    { strict: true },
    { message: 'Data de nascimento deve ser uma data válida no formato YYYY-MM-DD.' },
  )
  dateOfBirth!: string;

  @IsIn(PROFILE_GENDERS, {
    message: 'Sexo biológico deve ser masculino, feminino ou outro.',
  })
  gender!: string;

  @IsIn(RELATIONSHIP_TYPES, {
    message: 'Tipo de vínculo deve ser parent, legal_guardian, curator ou supported_decision.',
  })
  relationshipType!: RelationshipType;

  @Equals(true, { message: 'Consentimento LGPD é obrigatório.' })
  lgpdConsent!: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  lgpdLegalBasisNotes?: string;
}

/** Body of POST /v1/profiles/:id/legal-basis-confirmation (Art. 11, I re-confirmation, A3). */
export class ConfirmLegalBasisDto {
  @Equals(true, { message: 'Consentimento LGPD é obrigatório.' })
  lgpdConsent!: boolean;
}
