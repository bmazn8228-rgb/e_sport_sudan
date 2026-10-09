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
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen();
        }

        // Fast-path: Immediately route authoritative admin emails without network wait
        final emailRole = _authService.getRoleForEmail(user.email ?? '');
        if (emailRole != UserRole.player) {
          switch (emailRole) {
            case UserRole.referee:
              return RefereeDashboard();
            case UserRole.tournamentAdmin:
              return OrganizerDashboard();
            case UserRole.financeAdmin:
              return DepositRequestsScreen();
            case UserRole.superAdmin:
              return SuperAdminDashboard();
            case UserRole.player:
              break;
          }
        }

        // Regular players or custom-role users: listen to real-time role changes from Firestore
        return StreamBuilder<UserModel?>(
          stream: _firestoreService.getUserStream(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface),
                ),
              );
            }

            final userModel = userSnapshot.data;
            final effectiveRole = userModel?.role ?? UserRole.player;

            // Route each role to its dedicated dashboard in real time
            switch (effectiveRole) {
              case UserRole.player:
                return MainScreen();
              case UserRole.referee:
                return RefereeDashboard();
              case UserRole.tournamentAdmin:
                return OrganizerDashboard();
              case UserRole.financeAdmin:
                return DepositRequestsScreen();
              case UserRole.superAdmin:
                return SuperAdminDashboard();
            }
          },
        );
      },
    );
  }
}
