import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _firebaseUser;
  AppUser? _appUser;

  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        _appUser = await FirestoreService.getUser(user.uid);
      } else {
        _appUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user!;
      // Save user document
      final newUser = AppUser(id: user.uid, email: email);
      await FirestoreService.saveUser(newUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Generate invite code for caregiver linking
  Future<String> generateInviteCode() async {
    final code = DateTime.now().millisecondsSinceEpoch.toString().substring(
      4,
      10,
    );
    await FirestoreService.setInviteCode(_firebaseUser!.uid, code);
    // Refresh appUser
    _appUser = await FirestoreService.getUser(_firebaseUser!.uid);
    notifyListeners();
    return code;
  }
}
