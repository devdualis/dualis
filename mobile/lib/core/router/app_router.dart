import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/emergency/presentation/screens/emergency_screen.dart';
import '../../features/journal/presentation/screens/journal_flow_screen.dart';
import '../../features/journal/presentation/screens/my_conditions_screen.dart';
import '../../features/triage_outcome/domain/triage_outcome_models.dart';
import '../../features/triage_outcome/presentation/screens/triage_outcome_screen.dart';
import '../../features/dashboard/presentation/screens/check_in_summary_screen.dart';
import '../../features/dashboard/presentation/screens/historical_dashboard_screen.dart';
import '../../features/privacy/presentation/screens/privacy_center_screen.dart';
import '../../features/privacy/presentation/screens/terms_of_service_screen.dart';
import '../../features/privacy/presentation/screens/privacy_policy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/hydration/presentation/screens/hydration_dashboard_screen.dart';
import '../../features/profile/presentation/screens/family_sharing_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../presentation/screens/not_found_screen.dart';
import 'route_paths.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider =
    Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return createRouter(
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      if (authState.isLoading) return null;

      final isLoggedIn = authState.isAuthenticated;
      final currentLoc = state.uri.toString();
      final isAuthRoute = currentLoc == RoutePaths.onboarding ||
          currentLoc == RoutePaths.login ||
          currentLoc == RoutePaths.register ||
          currentLoc == RoutePaths.verifyEmail ||
          currentLoc == RoutePaths.forgotPassword ||
          currentLoc == RoutePaths.resetPassword;

      final isPublicAccessibleRoute = isAuthRoute ||
          currentLoc == RoutePaths.emergency ||
          currentLoc == RoutePaths.termsOfService ||
          currentLoc == RoutePaths.privacyPolicy ||
          currentLoc == RoutePaths.notFound;

      if (isLoggedIn && isAuthRoute) {
        return RoutePaths.home;
      }
      // An account still waiting for email verification reopens on the
      // verification screen instead of the start screen. Login, register
      // and help resources stay reachable.
      if (!isLoggedIn &&
          authState.pendingVerificationEmail != null &&
          currentLoc == RoutePaths.onboarding) {
        return RoutePaths.verifyEmail;
      }
      if (!isLoggedIn && !isPublicAccessibleRoute) {
        return RoutePaths.onboarding;
      }
      return null;
    },
  );
});

GoRouter createRouter({
  String initialLocation = RoutePaths.onboarding,
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: redirect,
    errorBuilder: (context, state) => NotFoundScreen(
      uri: state.uri.toString(),
    ),
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: RoutePaths.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        name: 'emergency',
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: RoutePaths.journal,
        name: 'journal',
        builder: (context, state) => JournalFlowScreen(
          args: state.extra as JournalFlowArgs? ?? const JournalFlowArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.myConditions,
        name: 'myConditions',
        builder: (context, state) => const MyConditionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.triageOutcome,
        name: 'triageOutcome',
        builder: (context, state) {
          final outcome = state.extra as TriageOutcome? ??
              TriageOutcome(
                id: 'default-outcome',
                vertical: 'physical',
                intensityScore: 0,
                primaryCategory: 'geral',
                categoryLabel: '',
                somaticMapping: '',
                recommendedArticles: const [],
                recordedAt: DateTime.now(),
              );
          return TriageOutcomeScreen(outcome: outcome);
        },
      ),
      GoRoute(
        path: RoutePaths.checkInSummary,
        name: 'checkInSummary',
        builder: (context, state) => CheckInSummaryScreen(
          args: state.extra as CheckInSummaryArgs? ??
              const CheckInSummaryArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.history,
        name: 'history',
        builder: (context, state) => const HistoricalDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacyCenter,
        name: 'privacyCenter',
        builder: (context, state) => const PrivacyCenterScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.hydration,
        name: 'hydration',
        builder: (context, state) => const HydrationDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.familySharing,
        name: 'familySharing',
        builder: (context, state) => const FamilySharingScreen(),
      ),
      GoRoute(
        path: RoutePaths.library,
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: RoutePaths.termsOfService,
        name: 'termsOfService',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: RoutePaths.notFound,
        name: 'notFound',
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
