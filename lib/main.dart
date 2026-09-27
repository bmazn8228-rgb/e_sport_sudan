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

  // Configure Status bar and Navigation bar for all Android skins (One UI, HyperOS, HiOS, ColorOS, etc.)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase with the connected project configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  runApp(const ESportSudanApp());
}

class ESportSudanApp extends StatelessWidget {
  const ESportSudanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: AppTheme.backgroundDark,
              body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
            ),
          );
        }

        final user = authSnapshot.data;

        return StreamBuilder<UserModel?>(
          stream: user != null ? FirestoreService().getUserStream(user.uid) : const Stream.empty(),
          builder: (context, userSnapshot) {
            final userSettings = userSnapshot.data?.settings ?? UserSettings();
            return _buildApp(userSettings);
          },
        );
      },
    );
  }

  Widget _buildApp(UserSettings settings) {
    return MaterialApp(
      title: 'E-Sport Sudan',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: settings.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      builder: (context, child) {
        return NetworkAwareWidget(
          child: Directionality(
            textDirection: settings.language == 'English' ? TextDirection.ltr : TextDirection.rtl,
            child: child!,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}
