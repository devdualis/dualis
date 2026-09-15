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

  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? dateOfBirth,
    String? picture,
    String? gender,
  });

  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  });
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

  @override
  Future<UserProfile> updateProfile({
    required String token,
    String? name,
    String? dateOfBirth,
    String? picture,
    String? gender,
  }) {
    return remoteDataSource.updateProfile(
      token: token,
      name: name,
      dateOfBirth: dateOfBirth,
      picture: picture,
      gender: gender,
    );
  }

  @override
  Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) {
    return remoteDataSource.changePassword(
      token: token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
