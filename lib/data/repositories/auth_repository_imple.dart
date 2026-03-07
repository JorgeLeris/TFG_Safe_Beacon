import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/auth/auth_api.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;

  const AuthRepositoryImpl({required AuthApi authApi}) : _authApi = authApi;

  @override
  Future<User?> createUserWithCredential(String email, String password) async {
    try {
      final user = await _authApi.createUserWithCredential(email, password);
      appLogger.info('User created successfully: ${user?.uid}');
      return user;
    } catch (e, st) {
      appLogger.severe('Error creating user:', e, st);
      return null;
    }
  }

  @override
  Future<User?> loginWithCredential(String email, String password) async {
    try {
      final user = await _authApi.loginWithCredential(email, password);
      appLogger.info('User logged in successfully: ${user?.uid}');
      return user;
    } catch (e, st) {
      appLogger.severe('Error logging in user:', e, st);
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authApi.logout();
      appLogger.info('User logged out successfully');
    } catch (e, st) {
      appLogger.severe('Error logging out user:', e, st);
    }
  }
}
