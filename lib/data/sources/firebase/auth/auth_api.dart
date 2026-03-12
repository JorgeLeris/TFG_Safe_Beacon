import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthApi {
  final _auth = FirebaseAuth.instance;

  // Sends an email verification link to the currently authenticated user.
  Future<void> sendEmailVerificationLink() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw Exception('No authenticated user or email already verified.');
    }
  }

  /// Reloads the currently authenticated user's data from the server.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Creates a new user with the given email and password.
  Future<User?> createUserWithCredential(String email, String password) async {
    final UserCredential credential = await _auth
        .createUserWithEmailAndPassword(email: email, password: password);
    return credential.user;
  }

  // Logs in the user with the given email and password.
  Future<User?> loginWithCredential(String email, String password) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  // Logs in the user with Google Sign-In.
  Future<({User? user, bool isNewUser})> loginWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    final googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return (
      user: userCredential.user,
      isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  // Logs out the currently authenticated user.
  Future<void> logout() => _auth.signOut();
}
