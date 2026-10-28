/// Summary of Brazil's Calendário Nacional de Vacinação (PNI, Ministério da
/// Saúde), bundled so it works offline. Shown as published: the app only
/// counts the doses the person registered. It never says a dose is late and
/// never recommends a vaccine (docs/bienestar/ANEXO-AUDITORIA-USO-PREVISTO.md §5).
/// Booster reminders use only [PniVaccine.boosterYears], the interval printed
/// in the calendar.
library;

const String pniSourceLabel = 'Calendário Nacional de Vacinação 2026 — Ministério da Saúde';
const String pniSourceUrl = 'https://www.gov.br/saude/pt-br/vacinacao/calendario';

enum PniStage { child, teen, adult, elderly, pregnant }

class PniVaccine {
  final String key;
  final String name;

  /// Doses listed in the calendar for this life stage; null = by campaign.
  final int? doses;

  /// Booster interval printed in the calendar (years), if any.
  final int? boosterYears;

  const PniVaccine(this.key, this.name, {this.doses, this.boosterYears});
}

const Map<PniStage, List<PniVaccine>> pniCalendar = {
  PniStage.child: [
    PniVaccine('bcg', 'BCG', doses: 1),
    PniVaccine('hepatite_b', 'Hepatite B (ao nascer)', doses: 1),
    PniVaccine('penta', 'Pentavalente (DTP/Hib/Hep B)', doses: 3),
    PniVaccine('vip', 'Poliomielite inativada (VIP)', doses: 4),
    PniVaccine('pneumo10', 'Pneumocócica 10-valente', doses: 3),
    PniVaccine('rotavirus', 'Rotavírus humano', doses: 2),
    PniVaccine('meningo_c', 'Meningocócica C', doses: 3),
    PniVaccine('febre_amarela', 'Febre amarela', doses: 2),
    PniVaccine('triplice_viral', 'Tríplice viral (sarampo, caxumba, rubéola)', doses: 2),
    PniVaccine('hepatite_a', 'Hepatite A', doses: 1),
    PniVaccine('dtp', 'DTP (reforços)', doses: 2),
    PniVaccine('varicela', 'Varicela', doses: 2),
    PniVaccine('covid19', 'Covid-19'),
    PniVaccine('influenza', 'Influenza (gripe)', boosterYears: 1),
  ],
  PniStage.teen: [
    PniVaccine('hpv', 'HPV', doses: 1),
    PniVaccine('meningo_acwy', 'Meningocócica ACWY', doses: 1),
    PniVaccine('hepatite_b', 'Hepatite B', doses: 3),
    PniVaccine('dt', 'dT (difteria e tétano)', doses: 3, boosterYears: 10),
    PniVaccine('febre_amarela', 'Febre amarela', doses: 1),
    PniVaccine('triplice_viral', 'Tríplice viral', doses: 2),
  ],
  PniStage.adult: [
    PniVaccine('hepatite_b', 'Hepatite B', doses: 3),
    PniVaccine('dt', 'dT (difteria e tétano)', doses: 3, boosterYears: 10),
    PniVaccine('febre_amarela', 'Febre amarela', doses: 1),
    PniVaccine('triplice_viral', 'Tríplice viral', doses: 2),
    PniVaccine('covid19', 'Covid-19'),
    PniVaccine('influenza', 'Influenza (gripe)', boosterYears: 1),
  ],
  PniStage.elderly: [
    PniVaccine('hepatite_b', 'Hepatite B', doses: 3),
    PniVaccine('dt', 'dT (difteria e tétano)', doses: 3, boosterYears: 10),
    PniVaccine('influenza', 'Influenza (gripe)', boosterYears: 1),
    PniVaccine('covid19', 'Covid-19'),
  ],
  PniStage.pregnant: [
    PniVaccine('dtpa', 'dTpa (a cada gestação)', doses: 1),
    PniVaccine('hepatite_b', 'Hepatite B', doses: 3),
    PniVaccine('influenza', 'Influenza (gripe)', boosterYears: 1),
    PniVaccine('covid19', 'Covid-19'),
    PniVaccine('vsr', 'Vírus sincicial respiratório (VSR)', doses: 1),
  ],
};

/// Life stage from the date of birth, as the calendar groups it.
PniStage pniStageFor(DateTime? birth, {DateTime? today}) {
  if (birth == null) return PniStage.adult;
  final now = today ?? DateTime.now();
  var age = now.year - birth.year;
  if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
  if (age < 10) return PniStage.child;
  if (age < 20) return PniStage.teen;
  if (age < 60) return PniStage.adult;
  return PniStage.elderly;
}

PniVaccine? pniVaccineByKey(String? key) {
  if (key == null) return null;
  for (final list in pniCalendar.values) {
    for (final v in list) {
      if (v.key == key) return v;
    }
  }
  return null;
}

/// Booster date from the published interval, or null when the calendar has none.
DateTime? pniBoosterDate(String? key, DateTime appliedOn) {
  final years = pniVaccineByKey(key)?.boosterYears;
  if (years == null) return null;
  return DateTime(appliedOn.year + years, appliedOn.month, appliedOn.day);
}
