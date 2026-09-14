import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/emergency/domain/emergency_context.dart';
import '../../features/emergency/domain/emergency_trigger_category.dart';
import '../../features/emergency/presentation/screens/emergency_screen.dart';
import '../../features/triage/domain/triage_vertical.dart';
import '../../features/triage/presentation/screens/triage_wizard_screen.dart';
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
          final vertical =
              state.extra as TriageVertical? ?? TriageVertical.psicoEmocional;
          return TriageWizardScreen(vertical: vertical);
        },
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
