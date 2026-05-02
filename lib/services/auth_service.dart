import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await credential.user?.updateDisplayName(name);
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return credential;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    // Create Firestore doc if new user
    final doc = await _firestore.collection('users').doc(userCred.user!.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(userCred.user!.uid).set({
        'name': userCred.user!.displayName ?? '',
        'email': userCred.user!.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return userCred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
