import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  /// Sends an email verification link to the current user.
  Future<void> sendEmailVerificationLink();

  /// Reloads the currently authenticated user.
  Future<void> reloadUser();

  /// Creates a new user with email and password.
  Future<User?> createUserWithCredential(String email, String password);

  /// Logs in the user with email and password.
  Future<User?> loginWithCredential(String email, String password);

  /// Logs in the user with Google Sign-In.
  Future<({User? user, bool isNewUser})?> loginWithGoogle();

  /// Logs out the current user.
  Future<void> logout();
}
