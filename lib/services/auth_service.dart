import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Sign Up with Email & Password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          name: name,
          role: role,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An error occurred during registration.');
    }
    return null;
  }

  // Sign In with Email & Password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        return await getUserProfile(result.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed.');
    }
    return null;
  }

  // Fetch complete profile details from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      throw Exception('Failed to fetch user profile.');
    }
    return null;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
