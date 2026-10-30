/// Health specialties offered as suggestions in the appointment form.
/// The person can still type one that is not here.
const _specialties = {
  'pt': [
    'Acupuntura', 'Alergia e imunologia', 'Anestesiologia', 'Angiologia', 'Cardiologia', 'Cirurgia geral',
    'Cirurgia plástica', 'Clínica médica', 'Coloproctologia', 'Dermatologia', 'Endocrinologia', 'Fisioterapia',
    'Fonoaudiologia', 'Gastroenterologia', 'Geriatria', 'Ginecologia e obstetrícia', 'Hematologia', 'Infectologia',
    'Mastologia', 'Medicina de família', 'Medicina do esporte', 'Nefrologia', 'Neurologia', 'Nutrição', 'Nutrologia',
    'Odontologia', 'Oftalmologia', 'Oncologia', 'Ortopedia', 'Otorrinolaringologia', 'Pediatria', 'Pneumologia',
    'Psicologia', 'Psiquiatria', 'Radiologia', 'Reumatologia', 'Urologia',
  ],
  'es': [
    'Acupuntura', 'Alergología e inmunología', 'Anestesiología', 'Angiología', 'Cardiología', 'Cirugía general',
    'Cirugía plástica', 'Coloproctología', 'Dermatología', 'Endocrinología', 'Fisioterapia', 'Fonoaudiología',
    'Gastroenterología', 'Geriatría', 'Ginecología y obstetricia', 'Hematología', 'Infectología', 'Mastología',
    'Medicina deportiva', 'Medicina familiar', 'Medicina interna', 'Nefrología', 'Neumología', 'Neurología',
    'Nutrición', 'Odontología', 'Oftalmología', 'Oncología', 'Otorrinolaringología', 'Pediatría', 'Psicología',
    'Psiquiatría', 'Radiología', 'Reumatología', 'Traumatología', 'Urología',
  ],
  'en': [
    'Acupuncture', 'Allergy and immunology', 'Anesthesiology', 'Cardiology', 'Colorectal surgery', 'Dentistry',
    'Dermatology', 'Endocrinology', 'Family medicine', 'Gastroenterology', 'General surgery', 'Geriatrics',
    'Hematology', 'Infectious diseases', 'Internal medicine', 'Nephrology', 'Neurology', 'Nutrition',
    'Obstetrics and gynecology', 'Oncology', 'Ophthalmology', 'Orthopedics', 'Otolaryngology (ENT)', 'Pediatrics',
    'Physiotherapy', 'Plastic surgery', 'Psychiatry', 'Psychology', 'Pulmonology', 'Radiology', 'Rheumatology',
    'Speech therapy', 'Sports medicine', 'Urology', 'Vascular medicine',
  ],
};

/// Specialties for [languageCode], falling back to Portuguese.
List<String> specialtiesFor(String languageCode) => _specialties[languageCode] ?? _specialties['pt']!;
