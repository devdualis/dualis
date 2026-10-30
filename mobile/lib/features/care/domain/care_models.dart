/// "Meus cuidados" records. Everything here is what the person typed or
/// confirmed; the app never computes doses, risks or judgments of values.
library;

enum CareKind {
  vaccineDose('vaccine_dose'),
  allergy('allergy'),
  medication('medication'),
  medicationIntake('medication_intake'),
  appointment('appointment');

  const CareKind(this.apiName);
  final String apiName;

  static CareKind fromApi(String value) =>
      CareKind.values.firstWhere((k) => k.apiName == value, orElse: () => CareKind.allergy);
}

enum IntakeAction { taken, snoozed, skipped }

enum DocumentKind { lab, prescription, other }

enum DocumentStatus { archived, processing, review, ready, failed }

class CareRecord {
  final String id;
  final CareKind kind;
  final String? parentId;
  final DateTime? occursAt;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const CareRecord({
    required this.id,
    required this.kind,
    required this.data,
    required this.createdAt,
    this.parentId,
    this.occursAt,
  });

  factory CareRecord.fromJson(Map<String, dynamic> json) => CareRecord(
        id: json['id'] as String,
        kind: CareKind.fromApi(json['kind'] as String),
        parentId: json['parentId'] as String?,
        occursAt: json['occursAt'] != null ? DateTime.parse(json['occursAt'] as String) : null,
        data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String? str(String key) {
    final v = data[key];
    return v is String && v.trim().isNotEmpty ? v : null;
  }

  int? integer(String key) => data[key] is int ? data[key] as int : null;

  double? number(String key) => data[key] is num ? (data[key] as num).toDouble() : null;
}

/// Medication as configured by the person.
class Medication {
  final CareRecord record;
  const Medication(this.record);

  String get id => record.id;
  String get name => record.str('name') ?? '';
  String? get strength => record.str('strength');
  String? get form => record.str('form');
  String? get amountPerIntake => record.str('amountPerIntake');
  String? get instructions => record.str('instructions');
  List<String> get times => List<String>.from(record.data['times'] as List? ?? const []);
  List<int> get weekdays => List<int>.from(record.data['weekdays'] as List? ?? const []);
  String? get untilOn => record.str('untilOn');
  String? get startOn => record.str('startOn');
  int? get stockCount => record.integer('stockCount');
  int? get stockWarnAt => record.integer('stockWarnAt');
  bool get active => record.data['active'] != false;

  String get title => [name, if (strength != null) strength].join(' ');

  bool get stockLow => stockCount != null && stockWarnAt != null && stockCount! <= stockWarnAt!;

  /// Whether the schedule the person set includes [day].
  bool takesOn(DateTime day) {
    if (!active) return false;
    final date = DateTime(day.year, day.month, day.day);
    final start = startOn != null ? DateTime.tryParse(startOn!) : null;
    final until = untilOn != null ? DateTime.tryParse(untilOn!) : null;
    if (start != null && date.isBefore(start)) return false;
    if (until != null && date.isAfter(until)) return false;
    return weekdays.isEmpty || weekdays.contains(day.weekday);
  }

  /// Scheduled moments on [day], in local time.
  List<DateTime> slotsOn(DateTime day) {
    if (!takesOn(day)) return const [];
    return times.map((t) {
      final parts = t.split(':');
      return DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
    }).toList()
      ..sort();
  }
}

class CareDocument {
  final String id;
  final DocumentKind kind;
  final String mime;
  final DocumentStatus status;
  final Map<String, dynamic> data;
  final String? error;
  final DateTime createdAt;

  /// Upload only: the same file was already stored for this profile and this is it.
  final bool duplicate;

  const CareDocument({
    required this.id,
    required this.kind,
    required this.mime,
    required this.status,
    required this.data,
    required this.createdAt,
    this.error,
    this.duplicate = false,
  });

  factory CareDocument.fromJson(Map<String, dynamic> json) => CareDocument(
        id: json['id'] as String,
        kind: DocumentKind.values.firstWhere((k) => k.name == json['kind'], orElse: () => DocumentKind.other),
        mime: json['mime'] as String? ?? 'application/octet-stream',
        status: DocumentStatus.values.firstWhere((s) => s.name == json['status'], orElse: () => DocumentStatus.failed),
        data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
        error: json['error'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        duplicate: json['duplicate'] == true,
      );

  String? get title => _s('title');
  /// Another document of the profile with the same exams (asked in the review, never removed by the app).
  String? get possibleDuplicateOf => _s('possibleDuplicateOf');
  String? get labName => _s('labName');
  String? get collectedOn => _s('collectedOn');
  bool get isPdf => mime == 'application/pdf';

  List<ExamValue> get values => (data['values'] as List? ?? const [])
      .map((v) => ExamValue.fromJson(Map<String, dynamic>.from(v as Map)))
      .toList();

  /// Exams in the document (headings as printed), in reading order.
  List<String> get sections => {
        for (final v in values)
          if (v.section != null && v.section!.trim().isNotEmpty) v.section!.trim(),
      }.toList();

  List<PrescribedItem> get medications => (data['medications'] as List? ?? const [])
      .map((v) => PrescribedItem.fromJson(Map<String, dynamic>.from(v as Map)))
      .toList();

  String? _s(String key) {
    final v = data[key];
    return v is String && v.trim().isNotEmpty ? v : null;
  }
}

/// One transcribed row: kept exactly as printed by the lab.
class ExamValue {
  /// Heading of the exam the row belongs to, as printed (a document can hold several exams).
  final String? section;
  final String item;
  final String value;
  final String? unit;
  final String? reference;
  final bool confirmed;

  const ExamValue({this.section, required this.item, required this.value, this.unit, this.reference, this.confirmed = false});

  factory ExamValue.fromJson(Map<String, dynamic> json) => ExamValue(
        section: json['section'] == null ? null : tidyExamName(json['section'] as String),
        item: tidyExamName(json['item'] as String? ?? ''),
        value: json['value'] as String? ?? '',
        unit: json['unit'] as String?,
        reference: json['reference'] as String?,
        confirmed: json['confirmed'] == true,
      );

  ExamValue copyWith({String? item, String? value, String? unit, String? reference, bool? confirmed}) => ExamValue(
        section: section,
        item: item ?? this.item,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        reference: reference ?? this.reference,
        confirmed: confirmed ?? this.confirmed,
      );

  Map<String, dynamic> toJson() => {
        if (section != null && section!.isNotEmpty) 'section': section,
        'item': tidyExamName(item),
        'value': value,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
        'confirmed': confirmed,
      };
}

const _shortWords = {'a', 'o', 'e', 'y', 'de', 'da', 'do', 'das', 'dos', 'del', 'la', 'el', 'em', 'en', 'com', 'con', 'sem', 'sin', 'por', 'pos', 'pre', 'no', 'na', 'of', 'and', 'the'};

/// One spelling per exam item, so "SEGMENTADOS :" and "Segmentados:" are the same item
/// (same rule as the backend's tidyName): only letters, digits and - / ( ) , . + % stay,
/// the ends lose punctuation and the name is in sentence case. Acronyms keep capitals:
/// words with digits, capitals inside a mixed-case name (HDL, HbA1c) and, in an
/// all-capitals name, words without vowels or of up to 3 letters (VCM, TGO).
String tidyExamName(String text) {
  final clean = text
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s\-/(),.+%]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[^\p{L}\p{N}(]+|[^\p{L}\p{N})%]+$', unicode: true), '');
  final allCaps = clean == clean.toUpperCase();
  final name = clean.split(' ').map((word) {
    final letters = word.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
    final rest = letters.length < 2 ? '' : letters.substring(1);
    final acronym = RegExp(r'\p{N}', unicode: true).hasMatch(word) ||
        (rest != rest.toLowerCase() &&
            (!allCaps ||
                !RegExp('[aeiouáàâãéêíóôõúü]', caseSensitive: false).hasMatch(letters) ||
                (letters.length <= 3 && !_shortWords.contains(letters.toLowerCase()))));
    return acronym ? word : word.toLowerCase();
  }).join(' ');
  return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

/// "/mm 3" and "/mm³" are the same unit read twice.
String examUnitKey(String? unit) => (unit ?? '').toLowerCase().replaceAll(' ', '').replaceAll('³', '3');

/// The number in a printed value ("13,8", "1.938", "245.000"), or null when it is not one
/// number (e.g. "Não reagente", "< 5").
double? examNumber(String value) {
  var text = value.trim();
  if (!RegExp(r'^\d[\d.,]*$').hasMatch(text)) return null;
  if (text.contains(',')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(text)) {
    text = text.replaceAll('.', '');
  }
  return double.tryParse(text);
}

/// A medicine read from a prescription, copied as written.
class PrescribedItem {
  final String name;
  final String? strength;
  final String? instructions;

  const PrescribedItem({required this.name, this.strength, this.instructions});

  factory PrescribedItem.fromJson(Map<String, dynamic> json) => PrescribedItem(
        name: json['name'] as String? ?? '',
        strength: json['strength'] as String?,
        instructions: json['instructions'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (strength != null && strength!.isNotEmpty) 'strength': strength,
        if (instructions != null && instructions!.isNotEmpty) 'instructions': instructions,
      };
}
