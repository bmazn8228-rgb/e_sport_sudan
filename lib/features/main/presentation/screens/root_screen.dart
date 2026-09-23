import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/features/main/presentation/screens/main_screen.dart';


import 'package:e_sport_sudan/features/roles/presentation/screens/referee_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/super_admin_dashboard.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/deposit_requests_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // User is logged in, fetch their role
        return FutureBuilder<UserModel?>(
          future: _firestoreService.getUser(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            final userModel = userSnapshot.data;

            if (userModel == null) {
              // If user is authenticated but not in firestore, treat as player or error
              // For now, let's sign out to reset state or just show MainScreen
              return const MainScreen();
            }

            // Route each role to its dedicated dashboard
            switch (userModel.role) {
              case UserRole.player:
                return const MainScreen();
              case UserRole.referee:
                return const RefereeDashboard();
              case UserRole.tournamentAdmin:
                return const OrganizerDashboard();
              case UserRole.financeAdmin:
                return const DepositRequestsScreen();
              case UserRole.superAdmin:
                return const SuperAdminDashboard();
            }
          },
        );
      },
    );
  }
}
