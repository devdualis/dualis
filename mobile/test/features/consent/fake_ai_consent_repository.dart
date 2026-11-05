import 'package:dio/dio.dart';
import 'package:dualis_mobile/features/consent/data/ai_consent_repository.dart';

/// In-memory AI consent server for widget tests and the QA harness.
///
/// - [granted]: current consent state.
/// - [fail]: every call throws a connection error (offline).
/// - [mismatchOnce]: the first grant throws [AiConsentVersionMismatch] and
///   the server moves to [nextVersion].
/// - [calls]: `status`, `grant:<version>`, `revoke`, in order.
class FakeAiConsentRepository implements AiConsentRepository {
  FakeAiConsentRepository({
    this.granted = false,
    this.fail = false,
    this.mismatchOnce = false,
    this.currentVersion = '2026.1',
    this.nextVersion = '2026.2',
    DateTime? grantedAt,
  }) : grantedAt = grantedAt ?? (granted ? DateTime(2026, 11, 5) : null),
       version = granted ? currentVersion : null;

  bool granted;
  bool fail;
  bool mismatchOnce;
  String currentVersion;
  final String nextVersion;
  String? version;
  DateTime? grantedAt;
  final List<String> calls = [];

  AiConsentStatus get _status => AiConsentStatus(
    granted: granted,
    version: version,
    currentVersion: currentVersion,
    grantedAt: granted ? grantedAt : null,
  );

  void _maybeFail(String path) {
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }
  }

  @override
  Future<AiConsentStatus> status() async {
    calls.add('status');
    _maybeFail('/v1/consents/ai-processing');
    return _status;
  }

  @override
  Future<AiConsentStatus> grant(String version) async {
    calls.add('grant:$version');
    _maybeFail('/v1/consents/ai-processing');
    if (mismatchOnce) {
      mismatchOnce = false;
      currentVersion = nextVersion;
      throw const AiConsentVersionMismatch();
    }
    if (version != currentVersion) throw const AiConsentVersionMismatch();
    granted = true;
    this.version = version;
    grantedAt = DateTime(2026, 11, 5);
    return _status;
  }

  @override
  Future<AiConsentStatus> revoke() async {
    calls.add('revoke');
    _maybeFail('/v1/consents/ai-processing');
    granted = false;
    return _status;
  }
}
