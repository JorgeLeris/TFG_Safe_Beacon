import 'package:firebase_auth/firebase_auth.dart';

class AuthApi {
  final _auth = FirebaseAuth.instance;

  Future<User?> createUserWithCredential(String email, String password) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);
    return credential.user;
  }

  Future<User?> loginWithCredential(String email, String password) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> logout() => _auth.signOut();
}
