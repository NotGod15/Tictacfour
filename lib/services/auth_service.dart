import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._private();
  static final AuthService instance = AuthService._private();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isGuest = false;

  User? get currentUser => _auth.currentUser;

  // for signing in with google account
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) return false;
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      isGuest = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    isGuest = false;
  }

  // this allows playing without signing in (guest mode)
  Future<bool> signInGuest() async {
    try {
      await _auth.signInAnonymously();
      isGuest = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  String _usernameToEmail(String username) {
    final sanitized = username.trim();
    return '$sanitized@tictacfour.local';
  }

  // creates new account with username and password
  // uses fake email format because firebase auth needs email
  Future<String?> signUpWithUsernameAndPassword({required String username, required String password}) async {
    try {
      final email = _usernameToEmail(username);
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(username);
      await _firestore.collection('usernames').doc(username).set({
        'uid': cred.user?.uid,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      isGuest = false;
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Username is already used';
      }
      return e.message ?? 'Sign up failed';
    } catch (e) {
      return 'Sign up failed';
    }
  }

  // for logging in with username and password
  Future<String?> signInWithUsernameAndPassword({required String username, required String password}) async {
    try {
      final email = _usernameToEmail(username);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      isGuest = false;
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'Login failed';
    }
  }

}
