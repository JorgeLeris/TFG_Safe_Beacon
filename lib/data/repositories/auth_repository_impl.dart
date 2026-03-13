import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/auth/auth_api.dart';
import 'package:safe_beacon/domain/auth/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;

  const AuthRepositoryImpl({required AuthApi authApi}) : _authApi = authApi;

  /// Sends an email verification link to the currently authenticated user.
  ///
  /// Throws an exception if the operation fails.
  @override
  Future<void> sendEmailVerificationLink() async {
    try {
      await _authApi.sendEmailVerificationLink();
    } catch (e, st) {
      appLogger.severe('Error sending email verification link:', e, st);
      rethrow;
    }
  }

  /// Reloads the currently authenticated user's data from the server.
  ///
  /// Throws an exception if the operation fails.
  @override
  Future<void> reloadUser() async {
    try {
      await _authApi.reloadUser();
      appLogger.info('User reloaded successfully');
    } catch (e, st) {
      appLogger.severe('Error reloading user:', e, st);
      rethrow;
    }
  }

  /// Creates a new user with the given [email] and [password].
  /// Returns the created [User] on success, or `null` if the operation fails.
  ///
  /// Throws an exception if the operation fails.
  @override
  Future<User?> createUserWithCredential(String email, String password) async {
    try {
      final user = await _authApi.createUserWithCredential(email, password);
      appLogger.info('User created successfully: ${user?.uid}');
      return user;
    } catch (e, st) {
      appLogger.severe('Error creating user:', e, st);
      rethrow;
    }
  }

  /// Logs in the user with the given [email] and [password].
  /// Returns the logged-in [User] on success, or `null` if the operation fails.
  ///
  /// Throws an exception if the operation fails.
  @override
  Future<User?> loginWithCredential(String email, String password) async {
    try {
      final user = await _authApi.loginWithCredential(email, password);
      appLogger.info('User logged in successfully: ${user?.uid}');
      return user;
    } catch (e, st) {
      appLogger.severe('Error logging in user:', e, st);
      rethrow;
    }
  }

  /// Logs in the user with Google Sign-In.
  /// Returns a record containing the logged-in [User] and a boolean indicating if
  /// the user is new on success, or `null` if the operation fails.
  ///
  /// Throws an exception if the operation fails.
  @override
  Future<({User? user, bool isNewUser})?> loginWithGoogle() async {
    try {
      final result = await _authApi.loginWithGoogle();
      appLogger.info(
        'User logged in with Google successfully: ${result.user?.uid}',
      );
      return result;
    } catch (e, st) {
      appLogger.severe('Error logging in with Google:', e, st);
      rethrow;
    }
  }

  /// Logs out the currently authenticated user.
  ///
  /// Throws an exception if the operation fails.
  @override
  Future<void> logout() async {
    try {
      await _authApi.logout();
      appLogger.info('User logged out successfully');
    } catch (e, st) {
      appLogger.severe('Error logging out user:', e, st);
    }
  }

  /// Sends a password reset email to the given [email].
  ///
  /// Throws an exception if the operation fails.
  @override
  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _authApi.sendPasswordResetLink(email);
      appLogger.info('Password reset link sent to: $email');
    } catch (e, st) {
      appLogger.severe('Error sending password reset link:', e, st);
      rethrow;
    }
  }
}
