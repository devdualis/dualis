import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/dualis_logo.dart';
import '../../../../shared/widgets/landscape_background.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/home_greeting.dart';
import '../../domain/trigger_checkin_state.dart';
import '../controllers/trigger_checkin_controller.dart';
import '../widgets/dual_axis_trigger_card.dart';
import '../../../sync/presentation/widgets/offline_indicator_banner.dart';
import '../../../sync/presentation/controllers/sync_outbox_worker.dart';
import '../../../settings/presentation/widgets/avatar_selector_sheet.dart';
import '../widgets/dualis_bottom_nav_bar.dart';
import '../widgets/today_triage_result_tab.dart';
import 'dart:async';
import '../../../dashboard/presentation/screens/historical_dashboard_screen.dart';
import '../../../journal_insights/presentation/controllers/journal_insights_controller.dart';
import '../../../triage_outcome/presentation/controllers/triage_outcome_controller.dart';
import '../../../../core/notifications/hydration_notification_service.dart';
import '../../../../core/notifications/daily_checkin_notification_service.dart';
import '../../../hydration/presentation/controllers/hydration_controller.dart';
import '../../../hydration/presentation/hydration_reminder_offer.dart';
import '../../../hydration/presentation/screens/hydration_dashboard_screen.dart';
import '../../../hydration/presentation/widgets/water_intake_modal.dart';
import '../../../profile/presentation/widgets/active_profile_banner.dart';
import '../../../profile/presentation/widgets/profile_app_bar_pill.dart';
import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
  StreamSubscription<String>? _notificationSub;
  StreamSubscription<String>? _checkinNotificationSub;

  @override
  void initState() {
    super.initState();
    _notificationSub = ref
        .read(hydrationNotificationServiceProvider)
        .onNotificationOpened
        .listen((payload) {
      if (payload == 'open_water_modal' && mounted) {
        final settings = ref.read(hydrationControllerProvider).settings;
        if (settings.trackingEnabled) {
          WaterIntakeModal.show(context, source: 'reminder_alarm');
        }
      }
    });

    _checkinNotificationSub = ref
        .read(dailyCheckinNotificationServiceProvider)
        .onNotificationOpened
        .listen((payload) {
      if (payload == 'open_checkin' && mounted) {
        setState(() => _currentTabIndex = 0);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authControllerProvider);
      if (authState.user == null) {
        await ref.read(authControllerProvider.notifier).restoreSession();
      }
      ref.read(triggerCheckInProvider.notifier).checkAndResetIfNewDay();
      ref.read(triggerCheckInProvider.notifier).loadTodayCheckIn();
      ref.read(triageOutcomeProvider.notifier).loadTodayOutcome();
      ref.read(hydrationControllerProvider.notifier).loadData();
      if (mounted && ref.read(authControllerProvider).isAuthenticated) {
        await ref.read(hydrationReminderOfferProvider).maybeShow(context);
      }
      if (mounted) {
        unawaited(
          ref.read(syncOutboxWorkerProvider.notifier).syncPendingOutbox(),
        );
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _checkinNotificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if ((prev == null || !prev.isAuthenticated) && next.isAuthenticated) {
        ref.read(triggerCheckInProvider.notifier).loadTodayCheckIn();
        ref.read(hydrationControllerProvider.notifier).loadData();
        unawaited(ref.read(hydrationReminderOfferProvider).maybeShow(context));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context);
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : '';
    final userEmail = (user?.email != null && user!.email.isNotEmpty)
        ? user.email
        : l10n.homeSessionActive;
    final activeProfileState = ref.watch(activeProfileControllerProvider);
    final delegatedProfile = showsDelegatedActiveProfile(ref)
        ? activeProfileState.activeProfile
        : null;
    final cardDisplayName = delegatedProfile?.name ?? userName;
    final cardDisplaySubtitle = delegatedProfile != null
        ? profileContextSubtitle(delegatedProfile, l10n)
        : userEmail;
    final cardAvatarInitial = cardDisplayName;
    final viewOnlyActive = activeProfileIsViewOnly(ref);
    ref.watch(syncOutboxWorkerProvider);
    ref.watch(hydrationControllerProvider);

    final triggerState = ref.watch(triggerCheckInProvider);

    Widget appBarTitle;
    List<Widget> appBarActions = [];

    if (_currentTabIndex == 0) {
      appBarTitle = DualisLogo(
        variant: DualisLogoVariant.horizontal,
        width: 160,
        withProtectionArea: false,
        onTap: () {
          if (_currentTabIndex != 0) {
            setState(() {
              _currentTabIndex = 0;
            });
          }
        },
      );
      appBarActions = [
        if (ref.watch(premiumProfilesEnabledProvider)) ...[
          const ProfileAppBarPill(),
          const SizedBox(width: 8),
        ],
        _AppBarIconButton(
          key: const Key('home_library_button'),
          icon: Icons.menu_book_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: l10n.xv2LibTitle,
          onTap: () => context.push(RoutePaths.library),
        ),
        const SizedBox(width: 8),
        _AppBarIconButton(
          key: const Key('home_settings_button'),
          icon: Icons.settings_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: 'Configurações',
          onTap: () => context.push(RoutePaths.settings),
        ),
        const SizedBox(width: 8),
      ];
    } else if (_currentTabIndex == 1) {
      appBarTitle = Text(
        AppLocalizations.of(context).navTodayOutcome,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      );
      appBarActions = [
        if (ref.watch(premiumProfilesEnabledProvider)) ...[
          const ProfileAppBarPill(),
          const SizedBox(width: 8),
        ],
        _AppBarIconButton(
          key: const Key('home_library_button'),
          icon: Icons.menu_book_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: l10n.xv2LibTitle,
          onTap: () => context.push(RoutePaths.library),
        ),
        const SizedBox(width: 8),
        _AppBarIconButton(
          key: const Key('home_settings_button'),
          icon: Icons.settings_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: 'Configurações',
          onTap: () => context.push(RoutePaths.settings),
        ),
        const SizedBox(width: 8),
      ];
    } else if (_currentTabIndex == 2) {
      appBarTitle = Text(
        l10n.xv2DashTitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      );
      appBarActions = [
        if (ref.watch(premiumProfilesEnabledProvider)) ...[
          const ProfileAppBarPill(),
          const SizedBox(width: 4),
        ],
        _AppBarIconButton(
          key: const Key('home_refresh_history_button'),
          icon: Icons.refresh_rounded,
          color: AppColors.clinicalTealDark,
          tooltip: 'Atualizar',
          onTap: () => ref.read(journalInsightsControllerProvider.notifier).refresh(),
        ),
        const SizedBox(width: 4),
        _AppBarIconButton(
          key: const Key('home_library_button'),
          icon: Icons.menu_book_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: l10n.xv2LibTitle,
          onTap: () => context.push(RoutePaths.library),
        ),
        const SizedBox(width: 8),
        _AppBarIconButton(
          key: const Key('home_settings_button'),
          icon: Icons.settings_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: 'Configurações',
          onTap: () => context.push(RoutePaths.settings),
        ),
        const SizedBox(width: 8),
      ];
    } else {
      appBarTitle = Text(
        'Controle de Hidratação 💧',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
        ),
      );
      appBarActions = [
        if (ref.watch(premiumProfilesEnabledProvider)) ...[
          const ProfileAppBarPill(),
          const SizedBox(width: 8),
        ],
        _AppBarIconButton(
          key: const Key('home_library_button'),
          icon: Icons.menu_book_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: l10n.xv2LibTitle,
          onTap: () => context.push(RoutePaths.library),
        ),
        const SizedBox(width: 8),
        _AppBarIconButton(
          key: const Key('home_settings_button'),
          icon: Icons.settings_outlined,
          color: AppColors.clinicalTealDark,
          tooltip: 'Configurações',
          onTap: () => context.push(RoutePaths.settings),
        ),
        const SizedBox(width: 8),
      ];
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: _currentTabIndex != 0,
        titleSpacing: 16,
        title: appBarTitle,
        actions: appBarActions,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicatorBanner(),
            Expanded(
              child: _buildCurrentTab(
                context,
                user,
                cardDisplayName,
                cardDisplaySubtitle,
                cardAvatarInitial,
                viewOnlyActive,
                triggerState,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DualisBottomNavBar(
        currentIndex: _currentTabIndex,
        hasCompletedToday: triggerState.isCompletedToday,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
        onEmergencyTap: () => context.push(RoutePaths.emergency),
      ),
    );
  }

  Widget _buildCurrentTab(
    BuildContext context,
    dynamic user,
    String cardDisplayName,
    String cardDisplaySubtitle,
    String cardAvatarInitial,
    bool viewOnlyActive,
    TriggerCheckInState triggerState,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeTab(
          context,
          user,
          cardDisplayName,
          cardDisplaySubtitle,
          cardAvatarInitial,
          viewOnlyActive,
          triggerState,
        );
      case 1:
        return TodayTriageResultTab(
          onGoToCheckIn: () {
            ref.read(triggerCheckInProvider.notifier).prepareForUpdate();
            setState(() => _currentTabIndex = 0);
          },
        );
      case 2:
        return const HistoricalDashboardScreen(isEmbedded: true);
      case 3:
        return const HydrationDashboardScreen(isEmbedded: true);
      default:
        return _buildHomeTab(
          context,
          user,
          cardDisplayName,
          cardDisplaySubtitle,
          cardAvatarInitial,
          viewOnlyActive,
          triggerState,
        );
    }
  }

  Widget _buildHomeTab(
    BuildContext context,
    dynamic user,
    String cardDisplayName,
    String cardDisplaySubtitle,
    String cardAvatarInitial,
    bool viewOnlyActive,
    TriggerCheckInState triggerState,
  ) {
    final useDelegatedAvatar = showsDelegatedActiveProfile(ref);

    // Subtle bundled landscape (strategy §12), same for everyone each day.
    return LandscapeBackground(
      spec: landscapeForDay(ref.read(homeClockProvider)()),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ActiveProfileBanner(),
        Expanded(
          child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              GestureDetector(
                key: const Key('home_profile_card'),
                onTap: () => context.push(RoutePaths.settings),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.clinicalTeal, AppColors.softIndigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.softIndigo.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                            picture: useDelegatedAvatar ? null : user?.picture,
                            fallbackInitial: cardAvatarInitial,
                            radius: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  useDelegatedAvatar
                                      ? AppLocalizations.of(context)
                                          .activeProfileCardTitle(
                                              cardDisplayName)
                                      : homeGreetingText(
                                          AppLocalizations.of(context),
                                          cardDisplayName,
                                          ref.read(homeClockProvider)(),
                                        ),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cardDisplaySubtitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).homeDataProtectedBadge,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 20),

              const DualAxisTriggerCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _AppBarIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
