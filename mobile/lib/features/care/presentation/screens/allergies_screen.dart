import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../domain/care_models.dart';
import '../care_providers.dart';
import '../widgets/care_widgets.dart';

/// Allergies the person informs, in their own words. The app never checks
/// medicines against them (docs/bienestar/PROPUESTA-CLIENTE-BIENESTAR.md §5).
class AllergiesScreen extends ConsumerWidget {
  const AllergiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canEdit = ref.watch(activeProfileControllerProvider).activeProfile?.canEdit ?? true;
    final async = ref.watch(careRecordsProvider(CareKind.allergy));
    final groups = {
      'medication': l10n.careAllergyMedication,
      'food': l10n.careAllergyFood,
      'other': l10n.careAllergyOther,
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: careAppBar(context, l10n.careAllergiesTitle),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              key: const Key('allergies_add'),
              backgroundColor: AppColors.dualisNavy,
              foregroundColor: Colors.white,
              onPressed: () => showCareSheet(context, (_) => const _AllergyForm()),
              icon: const Icon(Icons.add),
              label: Text(l10n.careAllergyAdd),
            )
          : null,
      body: CareAsync<List<CareRecord>>(
        value: async,
        onRetry: () => ref.invalidate(careRecordsProvider(CareKind.allergy)),
        data: (items) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text(l10n.careAllergiesIntro, style: careBody()),
            const SizedBox(height: 10),
            CareNote(l10n.careAllergiesNoCrossCheck),
            if (items.isEmpty) CareEmpty(l10n.careAllergiesEmpty, icon: Icons.no_food_outlined),
            for (final entry in groups.entries)
              if (items.any((a) => a.str('type') == entry.key)) ...[
                CareSection(entry.value),
                for (final a in items.where((a) => a.str('type') == entry.key)) ...[
                  const SizedBox(height: 8),
                  CareRow(
                    title: a.str('name') ?? '',
                    subtitle: [
                      if (a.str('reaction') != null) l10n.careAllergyReactionShown(a.str('reaction')!),
                      if (careDay(a.str('informedOn')) != null) l10n.careAllergyInformedOn(careDate(context, careDay(a.str('informedOn'))!)),
                      if (a.data['showOnProfile'] == true) l10n.careAllergyOnProfile,
                    ].join('\n'),
                    onTap: canEdit ? () => showCareSheet(context, (_) => _AllergyForm(existing: a)) : null,
                  ),
                ],
              ],
          ],
        ),
      ),
    );
  }
}

class _AllergyForm extends ConsumerStatefulWidget {
  const _AllergyForm({this.existing});
  final CareRecord? existing;

  @override
  ConsumerState<_AllergyForm> createState() => _AllergyFormState();
}

class _AllergyFormState extends ConsumerState<_AllergyForm> {
  late String _type = widget.existing?.str('type') ?? 'medication';
  late final _name = TextEditingController(text: widget.existing?.str('name'));
  late final _reaction = TextEditingController(text: widget.existing?.str('reaction'));
  late DateTime? _informed = careDay(widget.existing?.str('informedOn'));
  late bool _onProfile = widget.existing?.data['showOnProfile'] != false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _reaction.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      careSnack(context, l10n.careFillRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(careActionsProvider).save(
        CareKind.allergy,
        {
          'type': _type,
          'name': _name.text.trim(),
          if (_reaction.text.trim().isNotEmpty) 'reaction': _reaction.text.trim(),
          if (_informed != null) 'informedOn': isoDay(_informed!),
          'showOnProfile': _onProfile,
        },
        id: widget.existing?.id,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) careSnack(context, l10n.careSaveError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (!await confirmCareDelete(context)) return;
    await ref.read(careActionsProvider).delete(CareKind.allergy, widget.existing!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.existing == null ? l10n.careAllergyAdd : l10n.careAllergyEdit, style: careTitle(19))),
            if (widget.existing != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final (key, label) in [
              ('medication', l10n.careAllergyMedication),
              ('food', l10n.careAllergyFood),
              ('other', l10n.careAllergyOther),
            ])
              ChoiceChip(label: Text(label), selected: _type == key, onSelected: (_) => setState(() => _type = key)),
          ],
        ),
        const SizedBox(height: 10),
        CareField(fieldKey: const Key('allergy_name'), controller: _name, label: l10n.careAllergyName, maxLength: 80),
        const SizedBox(height: 10),
        CareField(fieldKey: const Key('allergy_reaction'), controller: _reaction, label: l10n.careAllergyReaction, maxLength: 200, maxLines: 2),
        const SizedBox(height: 10),
        CareDateField(label: l10n.careAllergyInformedField, value: _informed, onChanged: (d) => setState(() => _informed = d), lastDate: DateTime.now()),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.careAllergyShowOnProfile, style: careTitle(14)),
          subtitle: Text(l10n.careAllergyShowOnProfileHint, style: careBody(12)),
          value: _onProfile,
          onChanged: (v) => setState(() => _onProfile = v),
        ),
        const SizedBox(height: 4),
        CareNote(l10n.careAllergiesNoCrossCheck),
        const SizedBox(height: 14),
        FilledButton(
          key: const Key('allergy_save'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.dualisNavy, minimumSize: const Size.fromHeight(52)),
          onPressed: _busy ? null : _save,
          child: Text(l10n.careSave),
        ),
      ],
    );
  }
}
