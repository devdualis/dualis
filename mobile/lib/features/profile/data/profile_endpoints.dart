class ProfileEndpoints {
  static const String profiles = '/v1/profiles';
  static const String dependents = '/v1/profiles/dependents';
  static String profile(String id) => '/v1/profiles/$id';

  static const String invite = '/v1/family-sharing/invite';
  static const String accept = '/v1/family-sharing/accept';
  static String revoke(String grantId) => '/v1/family-sharing/revoke/$grantId';
  static const String grants = '/v1/family-sharing/grants';
}
