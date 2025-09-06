import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Sign Up with Email & Password
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // After creating the user, update their profile with the name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors (e.g., email-already-in-use)
      debugPrint(e.message);
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // Sign In with Email & Password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.message);
      return null;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}