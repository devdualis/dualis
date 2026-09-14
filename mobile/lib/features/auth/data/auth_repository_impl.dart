import '../domain/user_profile.dart';
import 'auth_remote_data_source.dart';

abstract class AuthRepository {
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<UserProfile> getProfile({required String token});
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? remoteSource})
      : remoteDataSource = remoteSource ?? AuthRemoteDataSource();

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String dateOfBirth,
    required bool lgpdConsent,
    String? disclaimerVersion,
  }) {
    return remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      gender: gender,
      dateOfBirth: dateOfBirth,
      lgpdConsent: lgpdConsent,
      disclaimerVersion: disclaimerVersion,
    );
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<UserProfile> getProfile({required String token}) {
    return remoteDataSource.getProfile(token: token);
  }
}
