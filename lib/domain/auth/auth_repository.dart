import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  Future<User?> createUserWithCredential(String email, String password);
  Future<User?> loginWithCredential(String email, String password);
  Future<User?> loginWithGoogle();
  Future<void> logout();
}
