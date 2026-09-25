import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/hydration_notification_service.dart';
import '../../../../shared/widgets/dualis_primary_button.dart';
import '../../domain/models/hydration_settings.dart';
import '../controllers/hydration_controller.dart';
import '../widgets/water_consumption_chart.dart';
import '../widgets/water_intake_modal.dart';

class HydrationDashboardScreen extends ConsumerWidget {
  final bool isEmbedded;
  const HydrationDashboardScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationControllerProvider);
    final notifier = ref.read(hydrationControllerProvider.notifier);

    final content = state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => notifier.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resultado do Dia & Controle de Consumo
                  _buildTodayHighlightCard(context, ref, state),
                  const SizedBox(height: 24),

                  // Histórico Diário (Registros de Hoje)
                  Text(
                    'Registros de Hoje',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTodayLogsList(context, ref, state),
                  const SizedBox(height: 24),

                  // Histórico & Tendências (Últimos 7 dias)
                  Text(
                    'Histórico Semanal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  WaterConsumptionChart(
                    last7DaysTotals: state.last7DaysTotals,
                    dailyTargetMl: state.dailyTargetMl,
                  ),
                  const SizedBox(height: 28),

                  // Ajustes e Notificações de Hidratação
                  Text(
                    'Ajustes & Lembretes de Hidratação',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHydrationSettingsCard(context, ref, state),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Controle de Hidratação 💧',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: content,
    );
  }

  Widget _buildTodayHighlightCard(
    BuildContext context,
    WidgetRef ref,
    HydrationState state,
  ) {
    final notifier = ref.read(hydrationControllerProvider.notifier);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.clinicalTeal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.clinicalTealDark,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Hoje',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '${state.todayTotalMl} / ${state.dailyTargetMl} ml',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.isGoalReached
                        ? AppColors.clinicalTealDark.withValues(alpha: 0.12)
                        : AppColors.softIndigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${state.progressPercent}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: state.isGoalReached
                          ? AppColors.clinicalTealDark
                          : AppColors.softIndigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.progressRatio.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  state.isGoalReached
                      ? AppColors.clinicalTealDark
                      : AppColors.clinicalTeal,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Adição Rápida:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('hydration_quick_add_200'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.clinicalTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => notifier.logWater(amountMl: 200, source: 'quick_chip'),
                    child: Text(
                      '+200 ml',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.clinicalTealDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('hydration_quick_add_300'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.clinicalTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => notifier.logWater(amountMl: 300, source: 'quick_chip'),
                    child: Text(
                      '+300 ml',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.clinicalTealDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('hydration_quick_add_500'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.clinicalTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => notifier.logWater(amountMl: 500, source: 'quick_chip'),
                    child: Text(
                      '+500 ml',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.clinicalTealDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DualisPrimaryButton(
              key: const Key('dashboard_add_water_button'),
              text: '+ Registrar Outro Volume',
              onPressed: () => WaterIntakeModal.show(context, source: 'dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLogsList(
    BuildContext context,
    WidgetRef ref,
    HydrationState state,
  ) {
    if (state.todayLogs.isEmpty) {
      return Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.surfaceLight,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Nenhum copo de água registrado hoje ainda.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      );
    }

    final reversed = state.todayLogs.reversed.toList();

    return Column(
      children: reversed.map((log) {
        final timeStr = DateFormat('HH:mm').format(log.timestamp);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: AppColors.surfaceLight,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.clinicalTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_drink_rounded,
                color: AppColors.clinicalTealDark,
                size: 20,
              ),
            ),
            title: Text(
              '${log.amountMl} ml',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              log.source == 'reminder_alarm'
                  ? 'Registrado via lembrete das $timeStr'
                  : 'Registrado às $timeStr',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
              onPressed: () {
                if (log.id != null) {
                  ref.read(hydrationControllerProvider.notifier).deleteLog(log.id!);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHydrationSettingsCard(
    BuildContext context,
    WidgetRef ref,
    HydrationState hydrationState,
  ) {
    final hydrationNotifier = ref.read(hydrationControllerProvider.notifier);
    final settings = hydrationState.settings;

    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const Key('settings_water_reminder_switch'),
              title: Text(
                'Lembrete a cada 2h (8h, 10h...)',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              subtitle: Text(
                'Alertas nos horários pares: 8h, 10h, 12h, 14h, 16h, 18h, 20h',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              value: settings.reminderEnabled,
              activeThumbColor: AppColors.clinicalTeal,
              onChanged: (val) => hydrationNotifier.toggleReminders(val),
            ),
            if (settings.reminderEnabled) ...[
              const Divider(height: 1, color: AppColors.outlineLight),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estilo do Lembrete:',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            key: const Key('settings_sound_style_chime'),
                            label: const Text('Aviso Suave (Mensagem)'),
                            selected: settings.reminderSoundStyle ==
                                ReminderSoundStyle.whatsappChime,
                            selectedColor: AppColors.clinicalTealDark,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: settings.reminderSoundStyle ==
                                      ReminderSoundStyle.whatsappChime
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                            onSelected: (val) {
                              if (val) {
                                hydrationNotifier.setSoundStyle(
                                    ReminderSoundStyle.whatsappChime);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            key: const Key('settings_sound_style_alarm'),
                            label: const Text('Alarme Telefônico'),
                            selected: settings.reminderSoundStyle ==
                                ReminderSoundStyle.phoneAlarm,
                            selectedColor: AppColors.clinicalTealDark,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: settings.reminderSoundStyle ==
                                      ReminderSoundStyle.phoneAlarm
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                            ),
                            onSelected: (val) {
                              if (val) {
                                hydrationNotifier.setSoundStyle(
                                    ReminderSoundStyle.phoneAlarm);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.outlineLight),
              SwitchListTile(
                key: const Key('settings_water_tracking_switch'),
                title: Text(
                  'Controle de quantidade consumida',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  settings.trackingEnabled
                      ? 'Abre tela para registrar ml consumidos no alerta'
                      : 'Apenas soa alarme no horário, sem registrar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                value: settings.trackingEnabled,
                activeThumbColor: AppColors.clinicalTeal,
                onChanged: (val) => hydrationNotifier.toggleTracking(val),
              ),
              const Divider(height: 1, color: AppColors.outlineLight),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.clinicalTeal),
                title: Text(
                  'Meta Diária de Hidratação',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  '${settings.dailyTargetMl} ml por dia',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                trailing: DropdownButton<int>(
                  value: settings.dailyTargetMl,
                  underline: const SizedBox.shrink(),
                  items: const [1500, 2000, 2500, 3000].map((val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text('$val ml'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      hydrationNotifier.setDailyTarget(val);
                    }
                  },
                ),
              ),
            ],
            const Divider(height: 1, color: AppColors.outlineLight),
            ListTile(
              key: const Key('settings_test_notification_tile'),
              leading: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.clinicalTeal),
              title: Text(
                'Testar Notificação Agora',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              subtitle: Text(
                'Dispara um alerta imediato na barra de notificações',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              trailing: const Icon(Icons.send_rounded,
                  color: AppColors.clinicalTeal, size: 20),
              onTap: () async {
                final service = ref.read(hydrationNotificationServiceProvider);
                await service.showImmediateReminder(
                  style: settings.reminderSoundStyle,
                  trackingEnabled: settings.trackingEnabled,
                  customBody:
                      '💧 Teste: Hora de Beber Água! Toque para interagir.',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Notificação de teste enviada! Verifique a barra de notificações.'),
                      backgroundColor: AppColors.clinicalTeal,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
