import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../care_routes.dart';
import '../widgets/care_widgets.dart';

/// "Meus cuidados" tab (premium): entry to vaccines, allergies, medications,
/// prescriptions, appointments, exams and the PDF summary of the active profile.
class CareHubScreen extends ConsumerStatefulWidget {
  const CareHubScreen({super.key});

  @override
  ConsumerState<CareHubScreen> createState() => _CareHubScreenState();
}

class _CareHubScreenState extends ConsumerState<CareHubScreen> {
  @override
  void initState() {
    super.initState();
    // Re-arm reminders whenever the tab opens (new device, profile switch).
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(careActionsProvider).rescheduleReminders());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meds = ref.watch(medicationsProvider).value ?? const <Medication>[];
    final doses = ref.watch(careRecordsProvider(CareKind.vaccineDose)).value;
    final allergies = ref.watch(careRecordsProvider(CareKind.allergy)).value;
    final appts = ref.watch(careRecordsProvider(CareKind.appointment)).value;
    final allDocs = ref.watch(careDocumentsProvider).value;
    final docs = allDocs?.where((d) => d.kind != DocumentKind.prescription).length;
    final prescriptions = allDocs?.where((d) => d.kind == DocumentKind.prescription).length;

    final now = DateTime.now();
    final todaySlots = [for (final m in meds) for (final s in m.slotsOn(now)) (m, s)]..sort((a, b) => a.$2.compareTo(b.$2));
    final next = todaySlots.where((e) => e.$2.isAfter(now)).firstOrNull;
    final upcoming = (appts ?? const <CareRecord>[])
        .where((a) => a.occursAt != null && a.occursAt!.isAfter(now))
        .toList()
      ..sort((a, b) => a.occursAt!.compareTo(b.occursAt!));
    final lowStock = meds.where((m) => m.active && m.stockLow).length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(careRecordsProvider);
        ref.invalidate(careDocumentsProvider);
      },
      child: ListView(
        key: const Key('care_hub_list'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [AppColors.dualisNavy, AppColors.dualisSymbolBlue]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.careHubToday, style: careBody().copyWith(color: Colors.white70)),
                      const SizedBox(height: 2),
                      Text(
                        todaySlots.isEmpty ? l10n.careHubNoRemindersToday : l10n.careHubRemindersToday(todaySlots.length),
                        style: careTitle(19).copyWith(color: Colors.white),
                      ),
                      if (next != null) ...[
                        const SizedBox(height: 4),
                        Text(l10n.careHubNext(next.$1.title, careTime(next.$2)), style: careBody().copyWith(color: Colors.white70)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.task_alt_rounded, color: Colors.white, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CareRow(
            key: const Key('care_hub_vaccines'),
            leading: const CareIconTile(Icons.vaccines_outlined),
            title: l10n.careVaccinesTitle,
            subtitle: doses == null ? null : l10n.careHubVaccinesSubtitle(doses.length),
            onTap: () => context.push(CarePaths.vaccines),
          ),
          const SizedBox(height: 10),
          CareRow(
            key: const Key('care_hub_allergies'),
            leading: const CareIconTile(Icons.no_food_outlined, background: CareColors.amberBg, foreground: CareColors.amber),
            title: l10n.careAllergiesTitle,
            subtitle: allergies == null
                ? null
                : allergies.isEmpty
                    ? l10n.careHubNone
                    : allergies.map((a) => a.str('name')).whereType<String>().take(3).join(', '),
            onTap: () => context.push(CarePaths.allergies),
          ),
          const SizedBox(height: 10),
          CareRow(
            key: const Key('care_hub_medications'),
            leading: const CareIconTile(Icons.medication_outlined, background: AppColors.softIndigoLight, foreground: AppColors.dualisNavy),
            title: l10n.careMedicationsTitle,
            subtitle: [
              l10n.careHubMedsActive(meds.where((m) => m.active).length),
              if (lowStock > 0) l10n.careHubLowStock(lowStock),
            ].join(' · '),
            onTap: () => context.push(CarePaths.medications),
          ),
          const SizedBox(height: 10),
          CareRow(
            key: const Key('care_hub_prescriptions'),
            leading: const CareIconTile(Icons.receipt_long_outlined, background: AppColors.softIndigoLight, foreground: AppColors.dualisNavy),
            title: l10n.careExamSectionPrescriptions,
            subtitle: prescriptions == null ? null : l10n.careHubPrescriptions(prescriptions),
            onTap: () => context.push(CarePaths.prescriptions),
          ),
          const SizedBox(height: 10),
          CareRow(
            key: const Key('care_hub_appointments'),
            leading: const CareIconTile(Icons.event_outlined, background: CareColors.greenBg, foreground: CareColors.green),
            title: l10n.careAppointmentsTitle,
            subtitle: upcoming.isEmpty
                ? l10n.careHubNoUpcoming
                : l10n.careHubNextAppointment(
                    careDate(context, upcoming.first.occursAt!),
                    upcoming.first.str('professional') ?? upcoming.first.str('specialty') ?? '',
                  ),
            onTap: () => context.push(CarePaths.appointments),
          ),
          const SizedBox(height: 10),
          CareRow(
            key: const Key('care_hub_exams'),
            leading: const CareIconTile(Icons.science_outlined, background: CareColors.slateBg, foreground: CareColors.slate),
            title: l10n.careExamsTitle,
            subtitle: docs == null ? null : l10n.careHubDocuments(docs),
            onTap: () => context.push(CarePaths.exams),
          ),
          const SizedBox(height: 10),
          CareRow(
            key: const Key('care_hub_summary'),
            leading: const CareIconTile(Icons.picture_as_pdf_outlined),
            title: l10n.careSummaryTitle,
            subtitle: l10n.careHubSummarySubtitle,
            onTap: () => context.push(CarePaths.summary),
          ),
        ],
      ),
    );
  }
}
