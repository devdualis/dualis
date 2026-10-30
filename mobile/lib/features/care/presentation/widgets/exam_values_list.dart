import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/care_models.dart';
import '../care_routes.dart';
import 'care_widgets.dart';

/// Rows shown per exam before "Show more".
const _rowsPerGroup = 4;

/// The search field appears once the list is longer than this.
const _searchFrom = 15;

/// One exam item across the checked lab documents: its latest result and the earlier
/// results in the same unit, oldest first.
class _Item {
  _Item(this.name, this.latest, this.date, this.points);
  final String name;
  final ExamValue latest;
  final String date;
  final List<double> points;
}

/// "My values over time": items grouped by the exam they belong to, each with its
/// latest value, date and a neutral line of its results. Never colours or judges a value.
class ExamValuesList extends StatefulWidget {
  const ExamValuesList(this.docs, {super.key});

  /// Checked lab documents.
  final List<CareDocument> docs;

  @override
  State<ExamValuesList> createState() => _ExamValuesListState();
}

class _ExamValuesListState extends State<ExamValuesList> {
  String _query = '';
  final Set<String> _expanded = {};

  /// Exam name → its items, exams and items in alphabetical order.
  Map<String, List<_Item>> _groups(AppLocalizations l10n) {
    final results = <String, List<(String date, String group, ExamValue v)>>{};
    for (final d in widget.docs) {
      final date = d.collectedOn ?? isoDay(d.createdAt);
      final sections = d.sections;
      final fallback = d.title ?? (sections.length == 1 ? sections.first : l10n.careExamValuesOtherGroup);
      for (final v in d.values) {
        if (v.item.isEmpty) continue;
        results.putIfAbsent(v.item.toLowerCase(), () => []).add((date, v.section ?? fallback, v));
      }
    }
    final groups = <String, List<_Item>>{};
    for (final rows in results.values) {
      rows.sort((a, b) => a.$1.compareTo(b.$1));
      final (date, group, latest) = rows.last;
      final unit = examUnitKey(latest.unit);
      final points = [
        for (final r in rows)
          if (examUnitKey(r.$3.unit) == unit) examNumber(r.$3.value),
      ].whereType<double>().toList();
      groups.putIfAbsent(group, () => []).add(_Item(latest.item, latest, date, points));
    }
    for (final items in groups.values) {
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return Map.fromEntries(groups.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = _groups(l10n);
    final count = all.values.fold<int>(0, (n, items) => n + items.length);
    final query = _query.trim().toLowerCase();
    final groups = query.isEmpty
        ? all
        : {
            for (final MapEntry(:key, :value) in all.entries)
              if (value.any((i) => i.name.toLowerCase().contains(query)))
                key: value.where((i) => i.name.toLowerCase().contains(query)).toList(),
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (count > _searchFrom) ...[
          TextField(
            key: const Key('exam_values_search'),
            onChanged: (text) => setState(() => _query = text),
            style: careBody(14).copyWith(color: AppColors.textPrimaryLight),
            decoration: InputDecoration(
              hintText: l10n.careExamValuesSearch,
              hintStyle: careBody(14),
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.outlineLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.outlineLight)),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (groups.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(l10n.careExamValuesNoMatch, style: careBody(), textAlign: TextAlign.center)),
        for (final MapEntry(key: group, value: items) in groups.entries) ...[
          _group(context, l10n, group, items, showAll: query.isNotEmpty || _expanded.contains(group)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _group(BuildContext context, AppLocalizations l10n, String group, List<_Item> items, {required bool showAll}) {
    final shown = showAll || items.length <= _rowsPerGroup + 1 ? items : items.take(_rowsPerGroup).toList();
    return CareCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.brandBgLightBlue,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Expanded(child: Text(group, style: careTitle(13))),
              Text(l10n.careExamValuesItemCount(items.length), style: careBody(11)),
            ]),
          ),
          for (final item in shown) _row(context, item),
          if (items.length > _rowsPerGroup + 1 && _query.trim().isEmpty)
            InkWell(
              onTap: () => setState(() => _expanded.contains(group) ? _expanded.remove(group) : _expanded.add(group)),
              child: Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineLight))),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Text(
                  showAll ? l10n.careExamValuesShowLess : l10n.careExamValuesShowMore(items.length - _rowsPerGroup),
                  style: careTitle(12).copyWith(color: AppColors.clinicalTeal),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, _Item item) => InkWell(
        key: Key('exam_values_${item.name}'),
        onTap: () => context.push(CarePaths.examItem, extra: item.name),
        child: Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineLight))),
          padding: const EdgeInsets.fromLTRB(14, 9, 8, 9),
          child: Row(children: [
            Expanded(child: Text(item.name, style: careBody(13).copyWith(color: AppColors.textPrimaryLight))),
            const SizedBox(width: 8),
            SizedBox(width: 48, height: 20, child: CustomPaint(painter: _Spark(item.points))),
            const SizedBox(width: 10),
            SizedBox(
              width: 104,
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  [item.latest.value, item.latest.unit].whereType<String>().join(' '),
                  style: careTitle(13),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(careDate(context, careDay(item.date)!), style: careBody(11)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight, size: 20),
          ]),
        ),
      );
}

/// Results in one unit as a plain line, scaled to their own range (no reference, no colour).
class _Spark extends CustomPainter {
  _Spark(this.points);
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = AppColors.clinicalTeal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final lo = points.reduce((a, b) => a < b ? a : b);
    final hi = points.reduce((a, b) => a > b ? a : b);
    Offset at(int i) => Offset(
          points.length == 1 ? size.width - 3 : 2 + i * (size.width - 4) / (points.length - 1),
          hi == lo ? size.height / 2 : size.height - 3 - (points[i] - lo) / (hi - lo) * (size.height - 6),
        );
    if (points.length == 1) {
      canvas.drawCircle(at(0), 3, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_Spark old) => old.points != points;
}
