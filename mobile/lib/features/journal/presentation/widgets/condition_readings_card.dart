import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/journal_keys.dart';
import '../../domain/journal_models.dart';

/// Reading fields of a tracked condition inside the physical check-in (v2.4,
/// Premium). One row per reading, each with its own time. Values are kept as
/// typed: the limits only catch typos and are never shown as a range, and no
/// value changes a colour or a label.
class ConditionReadingsCard extends StatefulWidget {
  /// Reading kinds the condition tracks ([JournalKeys.trackingKinds]).
  final List<String> tracking;

  /// Readings already in the draft (rows are rebuilt from them).
  final List<ConditionReading> initialReadings;

  /// Every complete reading whose values pass the typo limits, in row order.
  final ValueChanged<List<ConditionReading>> onChanged;

  /// Prefix of the field keys, e.g. `chronicTrack_c1`.
  final String keyPrefix;

  /// Clock for the default time of a new row; overridden in tests.
  final DateTime Function() now;

  const ConditionReadingsCard({
    super.key,
    required this.tracking,
    required this.onChanged,
    required this.keyPrefix,
    this.initialReadings = const [],
    this.now = DateTime.now,
  });

  @override
  State<ConditionReadingsCard> createState() => _ConditionReadingsCardState();
}

class _ConditionReadingsCardState extends State<ConditionReadingsCard> {
  final List<_ReadingRow> _rows = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialReadings.isNotEmpty) {
      for (final r in widget.initialReadings) {
        if (widget.tracking.contains(r.kind)) _rows.add(_ReadingRow.from(r, _changed));
      }
    }
    if (_rows.isEmpty) {
      for (final kind in widget.tracking) {
        _rows.add(_ReadingRow(kind, widget.now(), _changed));
      }
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    widget.onChanged([
      for (final r in _rows)
        if (r.reading() case final reading?) reading,
    ]);
  }

  void _addRow(String kind) {
    _rows.add(_ReadingRow(kind, widget.now(), _changed));
    _changed();
  }

  void _removeRow(_ReadingRow row) {
    _rows.remove(row);
    row.dispose();
    _changed();
  }

  Future<void> _pickKindAndAdd(AppLocalizations l10n) async {
    if (widget.tracking.length == 1) {
      _addRow(widget.tracking.single);
      return;
    }
    final kind = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.chronicTrackPickKind,
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            for (final k in widget.tracking)
              ListTile(
                key: Key('${widget.keyPrefix}_pick_$k'),
                title: Text(readingKindLabel(l10n, k)),
                onTap: () => Navigator.of(ctx).pop(k),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (kind != null && mounted) _addRow(kind);
  }

  Future<void> _pickTime(_ReadingRow row) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(row.measuredAt),
    );
    if (picked == null || !mounted) return;
    final now = widget.now();
    var at = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    // A time later than now is from yesterday (logging last night's reading).
    if (at.isAfter(now.add(JournalKeys.readingMaxAhead))) {
      at = at.subtract(const Duration(days: 1));
    }
    row.measuredAt = at;
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: Key('${widget.keyPrefix}_card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rows.length; i++)
          _rowView(l10n, _rows[i], i),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: Key('${widget.keyPrefix}_add'),
            onPressed: () => _pickKindAndAdd(l10n),
            child: Text(
              _rows.isEmpty ? l10n.chronicTrackAdd : l10n.chronicTrackAddAnother,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowView(AppLocalizations l10n, _ReadingRow row, int index) {
    final prefix = '${widget.keyPrefix}_$index';
    final check = l10n.chronicTrackCheckValue;
    final fields = <Widget>[];
    switch (row.kind) {
      case JournalKeys.trackingBloodPressure:
        fields.addAll([
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NumberField(
                  key: Key('${prefix}_systolic'),
                  controller: row.a,
                  focusNode: row.fa,
                  label: l10n.chronicTrackSystolic,
                  suffix: 'mmHg',
                  hint: '120',
                  error: row.errorOf(row.a, row.fa, JournalKeys.systolicLimit) ? check : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NumberField(
                  key: Key('${prefix}_diastolic'),
                  controller: row.b,
                  focusNode: row.fb,
                  label: l10n.chronicTrackDiastolic,
                  suffix: 'mmHg',
                  hint: '80',
                  error: row.errorOf(row.b, row.fb, JournalKeys.diastolicLimit) ? check : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _NumberField(
            key: Key('${prefix}_pulse'),
            controller: row.c,
            focusNode: row.fc,
            label: l10n.chronicTrackPulse,
            suffix: 'bpm',
            hint: '72',
            error: row.errorOf(row.c, row.fc, JournalKeys.pulseLimit) ? check : null,
          ),
        ]);
      case JournalKeys.trackingGlucose:
        fields.addAll([
          _NumberField(
            key: Key('${prefix}_mgdl'),
            controller: row.a,
            focusNode: row.fa,
            label: l10n.chronicTrackKindGlucose,
            suffix: 'mg/dL',
            hint: '98',
            error: row.errorOf(row.a, row.fa, JournalKeys.mgdlLimit) ? check : null,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.chronicTrackMoment,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in JournalKeys.glucoseMoments)
                ChoiceChip(
                  key: Key('${prefix}_moment_$m'),
                  label: Text(glucoseMomentLabel(l10n, m)),
                  selected: row.moment == m,
                  onSelected: (_) {
                    row.moment = row.moment == m ? null : m;
                    _changed();
                  },
                ),
            ],
          ),
        ]);
      case JournalKeys.trackingWeight:
        fields.add(_NumberField(
          key: Key('${prefix}_kg'),
          controller: row.a,
          focusNode: row.fa,
          label: l10n.chronicTrackKindWeight,
          suffix: 'kg',
          hint: '72,5',
          decimal: true,
          error: row.errorOf(row.a, row.fa, JournalKeys.kgLimit, decimal: true) ? check : null,
        ));
    }
    return Container(
      key: ObjectKey(row),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  readingKindLabel(l10n, row.kind),
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                key: Key('${prefix}_remove'),
                tooltip: l10n.chronicTrackRemove,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => _removeRow(row),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...fields,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.chronicTrackTime,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    ActionChip(
                      key: Key('${prefix}_time'),
                      avatar: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text(TimeOfDay.fromDateTime(row.measuredAt).format(context)),
                      backgroundColor: AppColors.dualisSymbolBlue.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onPressed: () => _pickTime(row),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Name of a reading kind.
String readingKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
      JournalKeys.trackingBloodPressure => l10n.chronicTrackKindBloodPressure,
      JournalKeys.trackingGlucose => l10n.chronicTrackKindGlucose,
      _ => l10n.chronicTrackKindWeight,
    };

/// Moment of a glucose reading, as the person picked it.
String glucoseMomentLabel(AppLocalizations l10n, String moment) => switch (moment) {
      JournalKeys.momentJejum => l10n.chronicTrackMomentJejum,
      JournalKeys.momentPreRefeicao => l10n.chronicTrackMomentPreRefeicao,
      JournalKeys.momentPosRefeicao => l10n.chronicTrackMomentPosRefeicao,
      _ => l10n.chronicTrackMomentDormir,
    };

/// Parses a weight typed with a comma or a dot ("72,5" or "72.5").
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// One reading being typed. Text fields a/b/c: systolic/diastolic/pulse for
/// blood pressure, the value for glucose and weight.
class _ReadingRow {
  final String kind;
  DateTime measuredAt;
  String? moment;
  final a = TextEditingController();
  final b = TextEditingController();
  final c = TextEditingController();
  final fa = FocusNode();
  final fb = FocusNode();
  final fc = FocusNode();

  _ReadingRow(this.kind, this.measuredAt, VoidCallback onChange) {
    _listen(onChange);
  }

  _ReadingRow.from(ConditionReading r, VoidCallback onChange)
      : kind = r.kind,
        measuredAt = r.measuredAt,
        moment = r.moment {
    switch (r.kind) {
      case JournalKeys.trackingBloodPressure:
        a.text = r.systolic?.toString() ?? '';
        b.text = r.diastolic?.toString() ?? '';
        c.text = r.pulse?.toString() ?? '';
      case JournalKeys.trackingGlucose:
        a.text = r.mgdl?.toString() ?? '';
      case JournalKeys.trackingWeight:
        a.text = _kgText(r.kg);
    }
    _listen(onChange);
  }

  static String _kgText(double? kg) {
    if (kg == null) return '';
    return kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toString().replaceAll('.', ',');
  }

  void _listen(VoidCallback onChange) {
    for (final t in [a, b, c]) {
      t.addListener(onChange);
    }
    for (final f in [fa, fb, fc]) {
      f.addListener(onChange);
    }
  }

  /// Out of the typo limits: right away above the top, below the bottom once
  /// the field is left (so typing "1" of "120" shows nothing).
  bool errorOf(
    TextEditingController t,
    FocusNode f,
    ReadingInputLimit limit, {
    bool decimal = false,
  }) {
    final text = t.text.trim();
    if (text.isEmpty) return false;
    final num? value = decimal ? parseDecimal(text) : int.tryParse(text);
    if (value == null) return true;
    if (value > limit.max) return true;
    return value < limit.min && !f.hasFocus;
  }

  /// The reading when complete and inside the limits; otherwise null.
  ConditionReading? reading() {
    final ConditionReading r;
    switch (kind) {
      case JournalKeys.trackingBloodPressure:
        final sys = int.tryParse(a.text.trim());
        final dia = int.tryParse(b.text.trim());
        final pulseText = c.text.trim();
        final pulse = int.tryParse(pulseText);
        if (sys == null || dia == null) return null;
        if (pulseText.isNotEmpty && pulse == null) return null;
        r = ConditionReading.bloodPressure(
          measuredAt: measuredAt,
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
        );
      case JournalKeys.trackingGlucose:
        final mgdl = int.tryParse(a.text.trim());
        if (mgdl == null || moment == null) return null;
        r = ConditionReading.glucose(measuredAt: measuredAt, mgdl: mgdl, moment: moment!);
      case JournalKeys.trackingWeight:
        final kg = parseDecimal(a.text);
        if (kg == null) return null;
        r = ConditionReading.weight(measuredAt: measuredAt, kg: kg);
      default:
        return null;
    }
    return r.valuesAccepted ? r : null;
  }

  void dispose() {
    for (final t in [a, b, c]) {
      t.dispose();
    }
    for (final f in [fa, fb, fc]) {
      f.dispose();
    }
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String suffix;
  final String hint;
  final String? error;
  final bool decimal;

  const _NumberField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.suffix,
    required this.hint,
    this.error,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    // Neutral outline and text for the typo hint: never an alarm colour.
    const neutral = OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.dualisNavy, width: 1.5),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        decimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            : FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(decimal ? 6 : 4),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: const OutlineInputBorder(),
        errorText: error,
        errorMaxLines: 2,
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.dualisNavy,
        ),
        errorBorder: neutral,
        focusedErrorBorder: neutral,
      ),
    );
  }
}
