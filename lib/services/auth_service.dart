import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Create AuthService to handle all authentication work
// Use singleton pattern so only one instance exist in whole app
class AuthService {
  AuthService._private();
  static final AuthService instance = AuthService._private();

  // Connect to Firebase Authentication and Google Sign-In
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // Track if current user is guest or real authenticated user
  bool isGuest = false;

  // Get current logged in user from Firebase
  User? get currentUser => _auth.currentUser;

  // Handle Google sign-in process
  
  Future<bool> signInWithGoogle() async {
    try {
      // Ask Google to show login window
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) return false; // User cancel login
      // Get authentication token from Google
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create credential for Firebase using Google token
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      await _auth.signInWithCredential(credential);
      isGuest = false; // Mark user as not guest
      return true;
    } catch (e) {
      // If error happen, return false to show error message
      return false;
    }
  }

  // sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
    isGuest = false;
  }

  // mark user as guest (no Firebase auth)
  void signInGuest() {
    isGuest = true;
  }
}
