const { Client } = require('pg');
const crypto = require('crypto');
require('dotenv').config();
require('dotenv').config({ path: 'backend/.env' });

const USER_ID = '916ea9fa-dc8f-468e-ac58-fe2bf289f6df'; // Ricardo Rincon

function encrypt(plaintext, keyHex) {
  if (!plaintext) return null;
  const key = Buffer.from(keyHex, 'hex');
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
  ciphertext += cipher.final('hex');
  const authTag = cipher.getAuthTag();
  return `v1:${iv.toString('hex')}:${authTag.toString('hex')}:${ciphertext}`;
}

const cases = [
  {
    system: 'cabeca_pescoco',
    intensity: 2,
    answers: { "0": "cabeca_pescoco", "1": "ha_alguns_dias", "2": "sim_telas_esforco_visual", "3": "2" },
    narrative: 'Cefaleia tensional e dor na região frontal e cervical após trabalho no computador.',
    disposition: 'auto_cuidado',
    hoursAgo: 48,
  },
  {
    system: 'cardiovascular_torax',
    intensity: 3,
    answers: { "0": "cardiovascular_torax", "1": "comecou_agora", "2": "nao_comecou_do_nada", "3": "3" },
    narrative: 'Sensação de aperto torácico leve e palpitações esporádicas aos esforços.',
    disposition: 'consulta_rotina',
    hoursAgo: 36,
  },
  {
    system: 'respiratorio',
    intensity: 2,
    answers: { "0": "respiratorio", "1": "ha_alguns_dias", "2": "sim_resfriado_sinusite", "3": "2" },
    narrative: 'Desconforto respiratório leve com coriza e tosse seca após mudança climática.',
    disposition: 'auto_cuidado',
    hoursAgo: 24,
  },
  {
    system: 'gastrointestinal_abdomen',
    intensity: 2,
    answers: { "0": "gastrointestinal_abdomen", "1": "ha_alguns_dias", "2": "nao_comecou_do_nada", "3": "2" },
    narrative: 'Azia e desconforto epigástrico após refeições pesadas.',
    disposition: 'auto_cuidado',
    hoursAgo: 60,
  },
  {
    system: 'coluna_dor_dorsal',
    intensity: 4,
    answers: { "0": "coluna_dor_dorsal", "1": "ha_alguns_dias", "2": "sim_postura_pescoco", "3": "4" },
    narrative: 'Dor lombar intensa ao levantar peso com rigidez na coluna dorsal.',
    disposition: 'pronto_atendimento',
    hoursAgo: 72,
  },
  {
    system: 'membros_superiores',
    intensity: 2,
    answers: { "0": "membros_superiores", "1": "ha_alguns_dias", "2": "cotovelo_esquerdo", "3": "2" },
    narrative: 'Dor e desconforto no cotovelo esquerdo após esforço repetitivo.',
    disposition: 'auto_cuidado',
    hoursAgo: 30,
  },
  {
    system: 'membros_inferiores',
    intensity: 3,
    answers: { "0": "membros_inferiores", "1": "comecou_agora", "2": "joelho_direito", "3": "3" },
    narrative: 'Dor moderada no joelho direito após caminhada prolongada e descida de escadas.',
    disposition: 'consulta_rotina',
    hoursAgo: 18,
  },
  {
    system: 'membros_inferiores',
    intensity: 2,
    answers: { "0": "membros_inferiores", "1": "ha_alguns_dias", "2": "tornozelo_esquerdo", "3": "2" },
    narrative: 'Leve desconforto e sensibilidade no tornozelo esquerdo.',
    disposition: 'auto_cuidado',
    hoursAgo: 50,
  },
  {
    system: 'neurologico',
    intensity: 3,
    answers: { "0": "neurologico", "1": "ha_alguns_dias", "2": "nao_comecou_do_nada", "3": "3" },
    narrative: 'Episódios de tontura e vertigem posicional leve ao levantar.',
    disposition: 'consulta_rotina',
    hoursAgo: 40,
  },
  {
    system: 'geniturinario_pelvico',
    intensity: 2,
    answers: { "0": "geniturinario_pelvico", "1": "ha_alguns_dias", "2": "nao_comecou_do_nada", "3": "2" },
    narrative: 'Leve desconforto na região pélvica e aumento de frequência urinária.',
    disposition: 'auto_cuidado',
    hoursAgo: 65,
  },
  {
    system: 'dermatologico',
    intensity: 2,
    answers: { "0": "dermatologico", "1": "ha_alguns_dias", "2": "nao_comecou_do_nada", "3": "2" },
    narrative: 'Prurido cutâneo e manchas avermelhadas de contato alérgico.',
    disposition: 'auto_cuidado',
    hoursAgo: 15,
  },
  {
    system: 'muscular_geral_sistemico',
    intensity: 3,
    answers: { "0": "muscular_geral_sistemico", "1": "ha_alguns_dias", "2": "sim_exercicio_intenso", "3": "3" },
    narrative: 'Mialgia difusa e sensação de fadiga muscular corporal generalizada.',
    disposition: 'auto_cuidado',
    hoursAgo: 55,
  },
  {
    system: 'endocrino_metabolico',
    intensity: 2,
    answers: { "0": "endocrino_metabolico", "1": "ha_alguns_dias", "2": "nao_comecou_do_nada", "3": "2" },
    narrative: 'Oscilação energética diária, cansaço matinal e sede aumentada.',
    disposition: 'auto_cuidado',
    hoursAgo: 70,
  },
];

async function seed() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();

  console.log('Connecting to database...');
  await client.query(`SELECT set_config('app.current_user_id', $1, false)`, [USER_ID]);

  const keyHex = process.env.ENCRYPTION_MASTER_KEY;

  for (const c of cases) {
    const encryptedNarrative = encrypt(c.narrative, keyHex);
    const encryptedAnswers = encrypt(JSON.stringify(c.answers), keyHex);
    const recordedAt = new Date(Date.now() - c.hoursAgo * 60 * 60 * 1000);

    const res = await client.query(
      `INSERT INTO symptom_logs (
        id, user_id, encrypted_narrative, intensity, anatomical_system,
        emotional_dimension, disposition, organic_primacy_applied,
        step_answers, recorded_at, created_at, updated_at
      ) VALUES (
        gen_random_uuid(), $1, $2, $3, $4, NULL, $5, false, $6, $7, $7, $7
      ) RETURNING id, anatomical_system, intensity, recorded_at`,
      [USER_ID, encryptedNarrative, c.intensity, c.system, c.disposition, encryptedAnswers, recordedAt]
    );

    console.log(`Inserted case for ${c.system} (level ${c.intensity}): ID ${res.rows[0].id}`);
  }

  await client.end();
  console.log('Finished seeding all physical cases successfully!');
}

seed().catch((err) => {
  console.error('Seed error:', err);
  process.exit(1);
});
