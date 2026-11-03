// CONTRACT (coordinator). Public API below is fixed; UI agents code against
// these members only.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/shared_access_grant.dart';

class ActiveProfileState {
  final List<Profile> profiles;
  final String? activeProfileId;
  final List<SharedAccessGrant> outgoingGrants;
  final List<SharedAccessGrant> incomingGrants;
  final bool isLoading;
  final String? errorMessage;

  const ActiveProfileState({
    this.profiles = const [],
    this.activeProfileId,
    this.outgoingGrants = const [],
    this.incomingGrants = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Falls back to the primary profile when nothing is selected.
  Profile? get activeProfile {
    for (final p in profiles) {
      if (p.id == activeProfileId) return p;
    }
    for (final p in profiles) {
      if (p.isPrimary) return p;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  List<Profile> get ownProfiles =>
      profiles.where((p) => p.ownership != ProfileOwnership.shared).toList();
  List<Profile> get sharedProfiles =>
      profiles.where((p) => p.ownership == ProfileOwnership.shared).toList();

  ActiveProfileState copyWith({
    List<Profile>? profiles,
    String? activeProfileId,
    List<SharedAccessGrant>? outgoingGrants,
    List<SharedAccessGrant>? incomingGrants,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActiveProfileState(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      outgoingGrants: outgoingGrants ?? this.outgoingGrants,
      incomingGrants: incomingGrants ?? this.incomingGrants,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ActiveProfileController extends Notifier<ActiveProfileState> {
  String? _userId;

  /// Bumped on every rebuild (sign-in, sign-out, account switch) so results of
  /// requests started for a previous session are dropped.
  int _session = 0;

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  ActiveProfileState build() {
    final userId = ref.watch(authControllerProvider
        .select((s) => s.isAuthenticated ? s.user?.id : null));
    _userId = userId;
    _session++;
    // A fresh state on every auth change: no profile data survives logout.
    if (userId == null) return const ActiveProfileState();
    Future.microtask(refresh);
    return const ActiveProfileState(isLoading: true);
  }

  /// Reloads profiles and grants from the API. Failures land in
  /// [ActiveProfileState.errorMessage]; this never throws.
  Future<void> refresh() async {
    final userId = _userId;
    final session = _session;
    if (userId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.fetchProfiles(),
        _repository.fetchGrants(),
      ]);
      if (!_isCurrent(session)) return;
      final profiles = results[0] as List<Profile>;
      final grants = results[1] as FamilySharingGrants;
      final wanted =
          state.activeProfileId ?? await _repository.readActiveProfileId(userId);
      if (!_isCurrent(session)) return;
      final activeId = profiles.any((p) => p.id == wanted) ? wanted : null;
      if (wanted != null && activeId == null) {
        unawaited(_repository.saveActiveProfileId(userId, null));
      }
      state = ActiveProfileState(
        profiles: profiles,
        activeProfileId: activeId,
        outgoingGrants: grants.outgoing,
        incomingGrants: grants.incoming,
      );
    } catch (e) {
      if (!_isCurrent(session)) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectProfile(String profileId) {
    final userId = _userId;
    if (userId == null || !state.profiles.any((p) => p.id == profileId)) return;
    state = state.copyWith(activeProfileId: profileId);
    unawaited(_repository.saveActiveProfileId(userId, profileId));
  }

  /// Creates a dependent (LGPD Art. 14 consent must be true), refreshes the
  /// list and makes the new dependent the active profile. Returns it.
  /// Throws [ProfileApiException] with the backend message on failure.
  Future<Profile> createDependent({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
    // parent | legal_guardian (under 18) or curator | supported_decision (18+)
    required String relationshipType,
    required bool lgpdConsent,
    String? lgpdLegalBasisNotes,
  }) async {
    final session = _requireSession();
    final profile = await _repository.createDependent(
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      relationshipType: relationshipType,
      lgpdConsent: lgpdConsent,
      lgpdLegalBasisNotes: lgpdLegalBasisNotes,
    );
    if (!_isCurrent(session)) return profile;
    state = state.copyWith(
      profiles: [...state.profiles.where((p) => p.id != profile.id), profile],
      activeProfileId: profile.id,
    );
    unawaited(_repository.saveActiveProfileId(_userId!, profile.id));
    await refresh();
    return profile;
  }

  /// Renames a profile (owner or CO_MANAGE only; UI hides it otherwise).
  /// Throws [ProfileApiException] on failure.
  Future<void> updateProfileName(String profileId, String name) async {
    final session = _requireSession();
    final updated = await _repository.updateProfileName(profileId, name);
    if (!_isCurrent(session)) return;
    state = state.copyWith(
      profiles: [
        for (final p in state.profiles) p.id == updated.id ? updated : p,
      ],
    );
  }

  /// Deletes an owned, non-primary profile and refreshes.
  /// Throws [ProfileApiException] on failure.
  Future<void> deleteProfile(String profileId) async {
    final session = _requireSession();
    await _repository.deleteProfile(profileId);
    if (!_isCurrent(session)) return;
    _replaceState(
      profiles: state.profiles.where((p) => p.id != profileId).toList(),
    );
    await refresh();
  }

  /// Returns the created PENDING outgoing grant (with inviteCode).
  /// Throws [ProfileApiException] on failure.
  Future<SharedAccessGrant> createInvite({
    required String targetProfileId,
    required ProfileShareLevel accessLevel,
    required GrantRelationship relationship,
    required List<ShareCategory> categories,
    bool dependentShareConfirmed = false,
  }) async {
    final session = _requireSession();
    final targetName = state.profiles
            .where((p) => p.id == targetProfileId)
            .map((p) => p.name)
            .firstOrNull ??
        '';
    final grant = await _repository.createInvite(
      targetProfileId: targetProfileId,
      accessLevel: accessLevel,
      relationship: relationship,
      categories: categories,
      dependentShareConfirmed: dependentShareConfirmed,
      targetProfileName: targetName,
    );
    if (_isCurrent(session)) {
      state = state.copyWith(outgoingGrants: [grant, ...state.outgoingGrants]);
    }
    return grant;
  }

  /// Changes what an outgoing grant shares, then reloads the lists.
  /// Throws [ProfileApiException] (e.g. 409 GRANT_SCOPE_LOCKED) on failure.
  Future<SharedAccessGrant> updateGrant(
    String grantId, {
    List<ShareCategory>? categories,
    GrantRelationship? relationship,
    bool dependentShareConfirmed = false,
  }) async {
    final session = _requireSession();
    final previous =
        state.outgoingGrants.where((g) => g.id == grantId).firstOrNull;
    final updated = await _repository.updateGrant(
      grantId,
      categories: categories,
      relationship: relationship,
      dependentShareConfirmed: dependentShareConfirmed,
      targetProfileName: previous?.targetProfileName ?? '',
    );
    if (!_isCurrent(session)) return updated;
    state = state.copyWith(outgoingGrants: [
      for (final g in state.outgoingGrants) g.id == grantId ? updated : g,
    ]);
    await refresh();
    return updated;
  }

  /// Accepts an invite code and refreshes, so the shared profile appears.
  /// Throws [ProfileApiException] (e.g. invalid/expired code) on failure.
  Future<void> acceptInvite(String inviteCode) async {
    final session = _requireSession();
    await _repository.acceptInvite(inviteCode.trim());
    if (!_isCurrent(session)) return;
    await refresh();
  }

  /// The young adult claims a profile with a transfer code. Reloads the list
  /// (the account's empty primary is replaced by the claimed profile) and
  /// makes the claimed profile active. Returns it.
  /// Throws [ProfileClaimException] on failure.
  Future<Profile> claimProfile(String code) async {
    final session = _requireSession();
    final claimed = await _repository.claimProfile(code.trim().toUpperCase());
    if (!_isCurrent(session)) return claimed;
    await refresh();
    if (_isCurrent(session)) selectProfile(claimed.id);
    return claimed;
  }

  /// The guardian generates (or regenerates) a transfer code for a dependent
  /// who turned 18. Reloads so the profile shows the active code.
  /// Throws [ProfileApiException] on failure.
  Future<HandoverCode> createHandoverCode(String profileId) async {
    final session = _requireSession();
    final code = await _repository.createHandoverCode(profileId);
    if (_isCurrent(session)) await refresh();
    return code;
  }

  /// The guardian re-confirms an adult dependent's legal basis under LGPD
  /// Art. 11, I, then reloads. Throws [ProfileApiException] on failure.
  Future<void> confirmLegalBasis(String profileId) async {
    final session = _requireSession();
    await _repository.confirmLegalBasis(profileId);
    if (!_isCurrent(session)) return;
    await refresh();
  }

  /// Revokes a grant (outgoing or incoming) and refreshes in the same session;
  /// if the active profile was the revoked shared one, falls back to primary.
  /// Throws [ProfileApiException] on failure.
  Future<void> revokeGrant(String grantId) async {
    final session = _requireSession();
    await _repository.revokeGrant(grantId);
    if (!_isCurrent(session)) return;

    final revokedIncoming =
        state.incomingGrants.where((g) => g.id == grantId).firstOrNull;
    final incoming =
        state.incomingGrants.where((g) => g.id != grantId).toList();
    var profiles = state.profiles;
    if (revokedIncoming != null &&
        !incoming.any((g) =>
            g.isActive && g.targetProfileId == revokedIncoming.targetProfileId)) {
      profiles = profiles
          .where((p) => !(p.isShared && p.id == revokedIncoming.targetProfileId))
          .toList();
    }
    _replaceState(
      profiles: profiles,
      // The API keeps revoked outgoing grants in the list; incoming drops them.
      outgoingGrants: [
        for (final g in state.outgoingGrants)
          g.id == grantId ? _revoked(g) : g,
      ],
      incomingGrants: incoming,
    );
    await refresh();
  }

  bool _isCurrent(int session) => ref.mounted && session == _session;

  int _requireSession() {
    if (_userId == null) {
      throw const ProfileApiException(
        'Sessão expirada. Faça login novamente.',
        statusCode: 401,
      );
    }
    return _session;
  }

  /// Applies list changes and drops the active selection if its profile is
  /// gone (copyWith cannot clear [ActiveProfileState.activeProfileId]).
  void _replaceState({
    required List<Profile> profiles,
    List<SharedAccessGrant>? outgoingGrants,
    List<SharedAccessGrant>? incomingGrants,
  }) {
    final activeId = state.activeProfileId;
    final activeGone =
        activeId != null && !profiles.any((p) => p.id == activeId);
    state = ActiveProfileState(
      profiles: profiles,
      activeProfileId: activeGone ? null : activeId,
      outgoingGrants: outgoingGrants ?? state.outgoingGrants,
      incomingGrants: incomingGrants ?? state.incomingGrants,
      isLoading: state.isLoading,
      errorMessage: state.errorMessage,
    );
    if (activeGone) {
      unawaited(_repository.saveActiveProfileId(_userId!, null));
    }
  }

  static SharedAccessGrant _revoked(SharedAccessGrant g) => SharedAccessGrant(
        id: g.id,
        direction: g.direction,
        targetProfileId: g.targetProfileId,
        targetProfileName: g.targetProfileName,
        accessLevel: g.accessLevel,
        status: GrantStatus.revoked,
        expiresAt: g.expiresAt,
        inviteCode: g.inviteCode,
        acceptedAt: g.acceptedAt,
      );
}

final activeProfileControllerProvider =
    NotifierProvider<ActiveProfileController, ActiveProfileState>(
  ActiveProfileController.new,
);
