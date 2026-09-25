import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingController extends Notifier<int> {
  @override
  int build() => 0;

  void onPageChanged(int index) {
    state = index;
  }
}

final onboardingControllerProvider =
    NotifierProvider.autoDispose<OnboardingController, int>(OnboardingController.new);
