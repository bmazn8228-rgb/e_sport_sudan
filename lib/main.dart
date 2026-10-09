import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'core/widgets/network_aware_widget.dart';

import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/services/firestore_service.dart';
import 'core/models/user_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI overlay is now handled inside _buildApp based on the current theme mode

  // Initialize Firebase with the connected project configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(ESportSudanApp());
}

class ESportSudanApp extends StatelessWidget {
  const ESportSudanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
            ),
          );
        }

        final user = authSnapshot.data;

        return StreamBuilder<UserModel?>(
          stream: user != null ? FirestoreService().getUserStream(user.uid) : Stream.empty(),
          builder: (context, userSnapshot) {
            final userSettings = userSnapshot.data?.settings ?? UserSettings();
            return _buildApp(context, userSettings);
          },
        );
      },
    );
  }

  Widget _buildApp(BuildContext context, UserSettings settings) {
    final themeMode = settings.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: settings.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: themeMode.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: settings.isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'E-Sport Sudan',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: themeMode,
      builder: (context, child) {
        return NetworkAwareWidget(
          child: Directionality(
            textDirection: settings.language == 'English' ? TextDirection.ltr : TextDirection.rtl,
            child: child!,
          ),
        );
      },
      home: SplashScreen(),
    );
  }
}

