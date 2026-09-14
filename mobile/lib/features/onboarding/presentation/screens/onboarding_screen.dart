import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/locale_provider.dart';
import '../../../../shared/widgets/language_picker_button.dart';
import '../../domain/value_card_item.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/animated_page_indicator.dart';
import '../widgets/carousel_card.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _shieldAnimController;
  late final Animation<double> _scaleAnimation;

  static const List<ValueCardItem> _items = [
    ValueCardItem(
      titleKey: 'valueCard1Title',
      bodyKey: 'valueCard1Body',
      accentColor: AppColors.clinicalTeal,
      icon: Icons.health_and_safety_outlined,
    ),
    ValueCardItem(
      titleKey: 'valueCard2Title',
      bodyKey: 'valueCard2Body',
      accentColor: AppColors.softIndigo,
      icon: Icons.lock_outline,
    ),
    ValueCardItem(
      titleKey: 'valueCard3Title',
      bodyKey: 'valueCard3Body',
      accentColor: AppColors.clinicalTeal,
      icon: Icons.verified_user_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _shieldAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _shieldAnimController,
      curve: Curves.easeOutCubic,
    );
    _shieldAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shieldAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch localeProvider to trigger dynamic UI updates on language change
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    final activeIndex = ref.watch(onboardingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: null,
        actions: const [
          LanguagePickerButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Branded Header with Animated Shield Icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softIndigo.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 32,
                        color: AppColors.softIndigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'DualisCheckUp',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.softIndigo,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Value Proposition Carousel (3 Cards)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .onPageChanged(index);
                  },
                  itemBuilder: (context, index) {
                    return CarouselCard(item: _items[index]);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Animated Page Indicator (active pill 24px, 300ms transition)
              AnimatedPageIndicator(
                count: _items.length,
                currentIndex: activeIndex,
              ),
              const SizedBox(height: 32),
              // Primary CTA: Criar Conta / Create Account -> /register
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('onboarding_register_button'),
                  onPressed: () {
                    context.push(RoutePaths.register);
                  },
                  child: Text(
                    l10n.screen1PrimaryCta,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary CTA: Entrar / Sign In -> /login
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  key: const Key('onboarding_login_button'),
                  onPressed: () {
                    context.push(RoutePaths.login);
                  },
                  child: Text(
                    l10n.screen1SecondaryCta,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
