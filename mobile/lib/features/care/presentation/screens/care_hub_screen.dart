import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/duotone_icon_tile.dart';
import '../../../journal/presentation/controllers/journal_flow_controller.dart' show userConditionsProvider;
import '../../../profile/domain/models/share_category.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../profile/presentation/widgets/not_shared_placeholder.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../care_routes.dart';
import '../widgets/care_widgets.dart';

/// "Meus cuidados" tab (premium): entry to vaccines, allergies, diseases & conditions,
/// medications, prescriptions, appointments, exams and the PDF summary of the active profile.
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
    // Care entries need the care category; the conditions row needs
    // conditions. Nothing is fetched for an area that was not shared.
    final canReadCare = activeProfileCanRead(ref, ShareCategory.care);
    final canReadConditions = activeProfileCanRead(ref, ShareCategory.conditions);
    final profileName = ref.watch(activeProfileControllerProvider).activeProfile?.name ?? '';
    if (!canReadCare && !canReadConditions) {
      return NotSharedPlaceholder(profileName: profileName);
    }
    final meds = canReadCare ? ref.watch(medicationsProvider).value ?? const <Medication>[] : const <Medication>[];
    final doses = canReadCare ? ref.watch(careRecordsProvider(CareKind.vaccineDose)).value : null;
    final allergies = canReadCare ? ref.watch(careRecordsProvider(CareKind.allergy)).value : null;
    final conditions = canReadConditions ? ref.watch(userConditionsProvider).value : null;
    final appts = canReadCare ? ref.watch(careRecordsProvider(CareKind.appointment)).value : null;
    final allDocs = canReadCare ? ref.watch(careDocumentsProvider).value : null;
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
        ref.invalidate(userConditionsProvider);
      },
      child: ListView(
        key: const Key('care_hub_list'),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          if (!canReadCare) NotSharedPlaceholder(profileName: profileName),
          if (canReadCare) ...[
            _TodayCard(
              title: todaySlots.isEmpty ? l10n.careHubNoRemindersToday : l10n.careHubRemindersToday(todaySlots.length),
              eyebrow: l10n.careHubToday,
              nextLine: next == null ? null : l10n.careHubNext(next.$1.title, careTime(next.$2)),
              appointmentLine: upcoming.isEmpty
                  ? null
                  : l10n.careHubNextAppointment(
                      careDate(context, upcoming.first.occursAt!),
                      upcoming.first.str('professional') ?? upcoming.first.str('specialty') ?? '',
                    ),
              times: [for (final (_, slot) in todaySlots) careTime(slot)],
            ),
            const SizedBox(height: 14),
          ],
          _TileGrid(
            tiles: [
              if (canReadCare)
                _CareTile(
                  key: const Key('care_hub_vaccines'),
                  icon: Icons.vaccines_outlined,
                  title: l10n.careVaccinesTitle,
                  subtitle: doses == null ? null : l10n.careHubVaccinesSubtitle(doses.length),
                  onTap: () => context.push(CarePaths.vaccines),
                ),
              if (canReadCare)
                _CareTile(
                  key: const Key('care_hub_allergies'),
                  icon: Icons.no_food_outlined,
                  title: l10n.careAllergiesTitle,
                  subtitle: allergies == null
                      ? null
                      : allergies.isEmpty
                          ? l10n.careHubNone
                          : allergies.map((a) => a.str('name')).whereType<String>().take(3).join(', '),
                  onTap: () => context.push(CarePaths.allergies),
                ),
              if (canReadConditions)
                _CareTile(
                  key: const Key('care_hub_conditions'),
                  icon: Icons.healing_outlined,
                  title: l10n.careConditionsTitle,
                  subtitle: conditions == null
                      ? null
                      : conditions.isEmpty
                          ? l10n.careHubNone
                          : conditions.map((c) => c.label).take(3).join(', '),
                  onTap: () => context.push(RoutePaths.myConditions),
                ),
              if (canReadCare)
                _CareTile(
                  key: const Key('care_hub_medications'),
                  icon: Icons.medication_outlined,
                  title: l10n.careMedicationsTitle,
                  subtitle: [
                    l10n.careHubMedsActive(meds.where((m) => m.active).length),
                    if (lowStock > 0) l10n.careHubLowStock(lowStock),
                  ].join(' · '),
                  onTap: () => context.push(CarePaths.medications),
                ),
              if (canReadCare)
                _CareTile(
                  key: const Key('care_hub_prescriptions'),
                  icon: Icons.receipt_long_outlined,
                  title: l10n.careExamSectionPrescriptions,
                  subtitle: prescriptions == null ? null : l10n.careHubPrescriptions(prescriptions),
                  onTap: () => context.push(CarePaths.prescriptions),
                ),
              if (canReadCare)
                _CareTile(
                  key: const Key('care_hub_appointments'),
                  icon: Icons.event_outlined,
                  title: l10n.careAppointmentsTitle,
                  subtitle: upcoming.isEmpty
                      ? l10n.careHubNoUpcoming
                      : l10n.careHubNextAppointment(
                          careDate(context, upcoming.first.occursAt!),
                          upcoming.first.str('professional') ?? upcoming.first.str('specialty') ?? '',
                        ),
                  onTap: () => context.push(CarePaths.appointments),
                ),
              if (canReadCare)
                _CareTile(
                  key: const Key('care_hub_exams'),
                  icon: Icons.science_outlined,
                  title: l10n.careExamsTitle,
                  subtitle: docs == null ? null : l10n.careHubDocuments(docs),
                  onTap: () => context.push(CarePaths.exams),
                ),
            ],
          ),
          if (canReadCare) ...[
            const SizedBox(height: 12),
            CareRow(
              key: const Key('care_hub_summary'),
              leading: const CareIconTile(Icons.picture_as_pdf_outlined),
              title: l10n.careSummaryTitle,
              subtitle: l10n.careHubSummarySubtitle,
              onTap: () => context.push(CarePaths.summary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Navy hero of the hub ("today" in the prototype): reminders, the next
/// medication and appointment, and the day's dose times.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.eyebrow, required this.title, this.nextLine, this.appointmentLine, required this.times});

  final String eyebrow;
  final String title;
  final String? nextLine;
  final String? appointmentLine;
  final List<String> times;

  @override
  Widget build(BuildContext context) {
    final muted = careBody().copyWith(color: Colors.white.withValues(alpha: 0.78));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.softIndigoDark.withValues(alpha: 0.7),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DuotoneIconTile(
                background: Colors.white.withValues(alpha: 0.12),
                child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: muted),
                    const SizedBox(height: 2),
                    Text(title, style: careTitle(18).copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          if (nextLine != null) ...[const SizedBox(height: 10), Text(nextLine!, style: muted)],
          if (appointmentLine != null) ...[
            SizedBox(height: nextLine == null ? 10 : 2),
            Text(appointmentLine!, style: muted),
          ],
          if (times.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in times.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 15, color: AppColors.dualisSymbolCyan),
                        const SizedBox(width: 6),
                        Text(t, style: careTitle(13.5).copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Two-column grid of equal-height tiles (a lone last tile keeps half width).
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 12),
              Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _CareTile extends StatelessWidget {
  const _CareTile({super.key, required this.icon, required this.title, this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CareCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 92),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CareIconTile(icon),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: careTitle(15.5)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: careBody(12.5)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
