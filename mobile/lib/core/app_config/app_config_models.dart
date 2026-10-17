class RemoteAppConfig {
  final String minSupportedVersion;

  const RemoteAppConfig({required this.minSupportedVersion});

  factory RemoteAppConfig.fromJson(Map<String, dynamic> json) {
    return RemoteAppConfig(
      minSupportedVersion: json['minSupportedVersion'] as String? ?? '1.0.0',
    );
  }
}
