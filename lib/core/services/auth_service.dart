import 'package:firebase_auth/firebase_auth.dart';
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
        return await _firestoreService.getUser(user.uid);
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
}
