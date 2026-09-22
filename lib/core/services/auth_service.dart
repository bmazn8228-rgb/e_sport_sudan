import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // Fetch user from Firestore to get their role
        UserModel? userModel = await _firestoreService.getUser(user.uid);
        if (userModel == null) {
          // Fallback: create a basic user doc if they exist in Auth but not Firestore
          userModel = UserModel(
            uid: user.uid,
            email: user.email ?? email,
            displayName: user.displayName ?? 'Player',
            phone: '',
            role: UserRole.player,
          );
          await _firestoreService.saveUser(userModel);
        }
        return userModel;
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    String? ign,
    String? gameId,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // Determine role based on hardcoded admin emails
        UserRole assignedRole = UserRole.player;
        final lowerEmail = email.toLowerCase();
        
        if (lowerEmail == 'superadmin@esportsudan.sd') {
          assignedRole = UserRole.superAdmin;
        } else if (lowerEmail == 'tournament@esportsudan.sd') {
          assignedRole = UserRole.tournamentAdmin;
        } else if (lowerEmail == 'referee@esportsudan.sd') {
          assignedRole = UserRole.referee;
        } else if (lowerEmail == 'finance@esportsudan.sd') {
          assignedRole = UserRole.financeAdmin;
        }

        // Create a new UserModel with the assigned role
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          ign: ign,
          gameId: gameId,
          phone: phone,
          role: assignedRole,
        );
        
        // Save to Firestore
        await _firestoreService.saveUser(newUser);
        return newUser;
      }
      return null;
    } catch (e) {
      debugPrint('Error registering: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not logged in or email is null');
      }
      
      // Re-authenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      
      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        UserCredential result = await _auth.signInWithCredential(credential);
        User? user = result.user;
        if (user != null) {
          UserModel? userModel = await _firestoreService.getUser(user.uid);
          // If this is a new user from Google, save basic info
          if (userModel == null) {
             userModel = UserModel(
                uid: user.uid,
                email: user.email ?? '',
                displayName: user.displayName ?? 'Google User',
                phone: '',
                role: UserRole.player,
             );
             await _firestoreService.saveUser(userModel);
          }
          return userModel;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }
}
