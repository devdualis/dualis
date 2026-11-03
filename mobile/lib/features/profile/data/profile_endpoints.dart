class ProfileEndpoints {
  static const String profiles = '/v1/profiles';
  static const String dependents = '/v1/profiles/dependents';
  static String profile(String id) => '/v1/profiles/$id';

  /// Hand-over at 18: the young adult claims a profile with a transfer code.
  static const String claim = '/v1/profiles/claim';
  static String handoverCode(String id) => '/v1/profiles/$id/handover-code';
  static String legalBasisConfirmation(String id) =>
      '/v1/profiles/$id/legal-basis-confirmation';

  static const String invite = '/v1/family-sharing/invite';
  static const String accept = '/v1/family-sharing/accept';
  static String revoke(String grantId) => '/v1/family-sharing/revoke/$grantId';
  static const String grants = '/v1/family-sharing/grants';
  static String grant(String grantId) => '/v1/family-sharing/grants/$grantId';
}
