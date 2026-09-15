import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/emergency/domain/emergency_context.dart';
import '../../features/emergency/domain/emergency_trigger_category.dart';
import '../../features/emergency/presentation/screens/emergency_screen.dart';
import '../../features/triage/domain/triage_vertical.dart';
import '../../features/triage/presentation/screens/triage_wizard_screen.dart';
import '../../features/triage_outcome/domain/triage_outcome_models.dart';
import '../../features/triage_outcome/presentation/screens/triage_outcome_screen.dart';
import '../../features/dashboard/presentation/screens/historical_dashboard_screen.dart';
import '../../features/privacy/presentation/screens/privacy_center_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return createRouter();
});

GoRouter createRouter({String initialLocation = RoutePaths.onboarding}) {
  return GoRouter(
    initialLocation: initialLocation,
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
        path: RoutePaths.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.emergency,
        name: 'emergency',
        builder: (context, state) {
          final emergencyContext = state.extra as EmergencyContext? ??
              EmergencyContext(
                category: EmergencyTriggerCategory.generalCriticalIntensity,
                severityLevel: 5,
                isEmotional: false,
                detectedAt: DateTime.now(),
              );
          return EmergencyScreen(emergencyContext: emergencyContext);
        },
      ),
      GoRoute(
        path: RoutePaths.triage,
        name: 'triage',
        builder: (context, state) {
          if (state.extra is TriageNavigationArgs) {
            final args = state.extra as TriageNavigationArgs;
            return TriageWizardScreen(
              vertical: args.initialVertical,
              isDual: args.isDual,
              naturalLanguageText: args.naturalLanguageText,
              preselectedCategoryKey: args.preselectedCategoryKey,
            );
          }
          final vertical =
              state.extra as TriageVertical? ?? TriageVertical.psicoEmocional;
          return TriageWizardScreen(vertical: vertical);
        },
      ),
      GoRoute(
        path: RoutePaths.triageOutcome,
        name: 'triageOutcome',
        builder: (context, state) {
          final outcome = state.extra as TriageOutcome? ??
              TriageOutcome(
                id: 'default-outcome',
                vertical: 'physical',
                intensityScore: 2,
                careDisposition: CareDisposition.selfCare,
                primaryCategory: 'geral',
                categoryLabel: 'Avaliação Física Geral',
                somaticMapping: 'Sintomas autolimitados',
                organicPrimacyApplied: false,
                recommendedArticles: const [],
                recordedAt: DateTime.now(),
              );
          return TriageOutcomeScreen(outcome: outcome);
        },
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
    ],
  );
}

final GoRouter appRouter = createRouter();
