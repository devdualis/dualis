import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../journal/data/journal_remote_data_source.dart';
import '../../../journal/domain/journal_models.dart';
import '../../../journal/presentation/journal_item_text.dart';
import '../../../journal/presentation/journal_labels.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../data/care_api.dart';
import '../../domain/care_models.dart';
import '../../domain/pni_calendar.dart';
import '../widgets/care_widgets.dart';

enum SummarySection { journal, conditions, medications, allergies, vaccines, exams, notes }

/// One line group of the summary; the same content goes to the screen and the PDF.
class SummaryBlock {
  final SummarySection section;
  final String title;
  final List<String> lines;
  const SummaryBlock(this.section, this.title, this.lines);
}

/// "Resumo dos meus registros": only what the person recorded in the period,
/// with no assessment or recommendation. Built on the device and shared only
/// if the person chooses to.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  int _days = 30;
  final Set<SummarySection> _sections = {
    SummarySection.journal,
    SummarySection.conditions,
    SummarySection.medications,
    SummarySection.allergies,
    SummarySection.notes,
  };
  List<SummaryBlock>? _blocks;
  bool _failed = false;
  int _loadId = 0;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    final id = ++_loadId;
    setState(() {
      _blocks = null;
      _failed = false;
    });
    try {
      final blocks = await _load();
      if (mounted && id == _loadId) setState(() => _blocks = blocks);
    } catch (e) {
      debugPrint('Summary load failed: $e');
      if (mounted && id == _loadId) setState(() => _failed = true);
    }
  }

  Future<List<SummaryBlock>> _load() async {
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final df = DateFormat.yMd(localeTag);
    final api = ref.read(careApiProvider);
    final journal = ref.read(journalRemoteDataSourceProvider);
    final from = DateTime.now().subtract(Duration(days: _days));

    final results = await Future.wait<Object>([
      journal.listEntries(days: _days).catchError((_) => <JournalEntry>[]),
      journal.listConditions().catchError((_) => <UserCondition>[]),
      api.list(CareKind.medication).catchError((_) => <CareRecord>[]),
      api.list(CareKind.allergy).catchError((_) => <CareRecord>[]),
      api.list(CareKind.vaccineDose).catchError((_) => <CareRecord>[]),
      api.documents(kind: DocumentKind.lab).catchError((_) => <CareDocument>[]),
    ]);
    final entries = (results[0] as List<JournalEntry>).where((e) => e.recordedAt.isAfter(from)).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final conditions = results[1] as List<UserCondition>;
    final meds = (results[2] as List<CareRecord>).map(Medication.new).toList();
    final allergies = results[3] as List<CareRecord>;
    final doses = results[4] as List<CareRecord>;
    final exams = (results[5] as List<CareDocument>).where((d) => d.status == DocumentStatus.ready).toList();

    final intakeCounts = <String, (int, int)>{};
    for (final m in meds) {
      final intakes = await api.list(CareKind.medicationIntake, parentId: m.id).catchError((_) => <CareRecord>[]);
      final inPeriod = intakes.where((i) => i.occursAt != null && i.occursAt!.isAfter(from));
      final taken = inPeriod.where((i) => i.str('action') == 'taken').length;
      final marked = inPeriod.where((i) => i.str('action') != 'snoozed').length;
      intakeCounts[m.id] = (taken, marked);
    }

    String item(JournalItem i) =>
        [journalItemTitle(l10n, i), if (i.intensity != null) l10n.careSummaryIntensity(i.intensity!)].join(' · ');

    return [
      SummaryBlock(SummarySection.journal, l10n.careSummaryJournal(entries.length), [
        for (final e in entries)
          [
            '${df.format(e.recordedAt.toLocal())}: ${JournalLabels.mood(l10n, e.mood)}',
            ...e.items.map(item),
          ].join(' — '),
      ]),
      SummaryBlock(SummarySection.conditions, l10n.careSummaryConditions, [
        for (final c in conditions) c.label,
      ]),
      SummaryBlock(SummarySection.medications, l10n.careSummaryMedications, [
        for (final m in meds.where((m) => m.active))
          [
            m.title,
            if (m.amountPerIntake != null) m.amountPerIntake!,
            m.times.join(', '),
            if (intakeCounts[m.id] != null && intakeCounts[m.id]!.$2 > 0)
              l10n.careSummaryTaken(intakeCounts[m.id]!.$1, intakeCounts[m.id]!.$2),
          ].join(' · '),
      ]),
      SummaryBlock(SummarySection.allergies, l10n.careAllergiesTitle, [
        for (final a in allergies) [a.str('name'), a.str('reaction')].whereType<String>().join(' — '),
      ]),
      SummaryBlock(SummarySection.vaccines, l10n.careVaccinesTitle, [
        for (final d in doses)
          [
            d.str('customName') ?? pniVaccineByKey(d.str('vaccineKey'))?.name ?? '',
            d.str('doseLabel'),
            if (careDay(d.str('appliedOn')) != null) df.format(careDay(d.str('appliedOn'))!),
            if (d.str('batch') != null) l10n.careVaccineBatch(d.str('batch')!),
          ].whereType<String>().join(' · '),
      ]),
      SummaryBlock(SummarySection.exams, l10n.careExamsTitle, [
        for (final doc in exams)
          for (final v in doc.values)
            [
              v.item,
              [v.value, v.unit].whereType<String>().join(' '),
              if (v.reference != null) l10n.careSummaryReference(v.reference!),
              [doc.collectedOn, doc.labName].whereType<String>().join(' '),
            ].where((s) => s.isNotEmpty).join(' · '),
      ]),
      SummaryBlock(SummarySection.notes, l10n.careSummaryNotes, [
        for (final e in entries)
          if (e.note != null && e.note!.trim().isNotEmpty) '${df.format(e.recordedAt.toLocal())}: "${e.note!.trim()}"',
      ]),
    ];
  }

  Future<Uint8List> _pdf(List<SummaryBlock> blocks) async {
    final l10n = AppLocalizations.of(context);
    final df = DateFormat.yMd(Localizations.localeOf(context).toLanguageTag());
    final name = ref.read(activeProfileControllerProvider).activeProfile?.name ?? '';
    final now = DateTime.now();
    final doc = pw.Document(title: l10n.careSummaryTitle, author: 'Dualis');
    const navy = PdfColor.fromInt(0xFF0E3E6C);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => pw.Text(
          '${l10n.careSummaryFooter}   ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        build: (ctx) => [
          pw.Text(l10n.careSummaryTitle, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: navy)),
          pw.SizedBox(height: 4),
          pw.Text(
            l10n.careSummaryHeader(name, df.format(now.subtract(Duration(days: _days))), df.format(now)),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Divider(color: PdfColors.grey400),
          for (final b in blocks.where((b) => _sections.contains(b.section))) ...[
            pw.SizedBox(height: 8),
            pw.Text(b.title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: navy)),
            pw.SizedBox(height: 3),
            if (b.lines.isEmpty)
              pw.Text(l10n.careSummaryNothing, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
            else
              for (final line in b.lines) pw.Bullet(text: line, style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _share(List<SummaryBlock> blocks) async {
    final l10n = AppLocalizations.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _sharing = true);
    try {
      final bytes = await _pdf(blocks);
      final fileName = 'dualis-resumo-${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName)],
        fileNameOverrides: [fileName],
        subject: l10n.careSummaryTitle,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      SummarySection.journal: l10n.careSectionJournal,
      SummarySection.conditions: l10n.careSectionConditions,
      SummarySection.medications: l10n.careSectionMedications,
      SummarySection.allergies: l10n.careSectionAllergies,
      SummarySection.vaccines: l10n.careSectionVaccines,
      SummarySection.exams: l10n.careSectionExams,
      SummarySection.notes: l10n.careSectionNotes,
    };
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, l10n.careSummaryTitle),
      body: Builder(
        builder: (context) {
          final blocks = _blocks;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 7, label: Text(l10n.careDays(7))),
                  ButtonSegment(value: 30, label: Text(l10n.careDays(30))),
                  ButtonSegment(value: 90, label: Text(l10n.careDays(90))),
                ],
                selected: {_days},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  _days = s.first;
                  _reload();
                },
              ),
              const SizedBox(height: 12),
              Text(l10n.careSummaryInclude, style: careTitle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in SummarySection.values)
                    FilterChip(
                      label: Text(labels[s]!),
                      selected: _sections.contains(s),
                      onSelected: (on) => setState(() => on ? _sections.add(s) : _sections.remove(s)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              CareCard(
                key: const Key('summary_preview'),
                child: _failed
                    ? CareAsync<void>(value: const AsyncValue.error('load', StackTrace.empty), data: (_) => const SizedBox(), onRetry: _reload)
                    : blocks == null
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.careSummaryTitle, style: careTitle(16).copyWith(color: AppColors.dualisNavy)),
                          const SizedBox(height: 6),
                          for (final b in blocks.where((b) => _sections.contains(b.section))) ...[
                            const SizedBox(height: 8),
                            Text(b.title, style: careTitle(13)),
                            if (b.lines.isEmpty) Text(l10n.careSummaryNothing, style: careBody(12)),
                            for (final line in b.lines.take(4)) Text('• $line', style: careBody(12)),
                            if (b.lines.length > 4) Text(l10n.careSummaryMore(b.lines.length - 4), style: careBody(12)),
                          ],
                          const Divider(height: 24),
                          Text(l10n.careSummaryFooter, style: careBody(11)),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('summary_share'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(52)),
                onPressed: blocks == null || _sharing ? null : () => _share(blocks),
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.careSummaryShare),
              ),
              const SizedBox(height: 10),
              CareNote(l10n.careSummaryPrivacy),
            ],
          );
        },
      ),
    );
  }
}
