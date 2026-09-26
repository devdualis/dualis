// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'triage_wizard_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TriageWizardNotifier)
final triageWizardProvider = TriageWizardNotifierProvider._();

final class TriageWizardNotifierProvider
    extends $NotifierProvider<TriageWizardNotifier, TriageWizardState> {
  TriageWizardNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'triageWizardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$triageWizardNotifierHash();

  @$internal
  @override
  TriageWizardNotifier create() => TriageWizardNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TriageWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TriageWizardState>(value),
    );
  }
}

String _$triageWizardNotifierHash() =>
    r'd5bc96138b1659b8944f7d8ebc81c959dbb8c394';

abstract class _$TriageWizardNotifier extends $Notifier<TriageWizardState> {
  TriageWizardState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TriageWizardState, TriageWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TriageWizardState, TriageWizardState>,
              TriageWizardState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
