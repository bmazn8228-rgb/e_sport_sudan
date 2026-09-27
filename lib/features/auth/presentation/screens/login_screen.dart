import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/utils/validators.dart';
import 'package:e_sport_sudan/core/utils/connectivity_helper.dart';
import 'package:e_sport_sudan/features/main/presentation/screens/main_screen.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/features/main/presentation/screens/root_screen.dart';
import 'register_screen.dart';

import 'package:e_sport_sudan/core/services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledEmail;
  const LoginScreen({super.key, this.prefilledEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _enableBiometricForFuture = false;
  bool _canUseBiometric = false;
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null) {
      _identifierController.text = widget.prefilledEmail!;
    }
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final supported = await _biometricService.canAuthenticate();
    final hasCreds = await _biometricService.hasSavedCredentials();
    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
        _canUseBiometric = supported && hasCreds;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await _biometricService.authenticate(
      reason: 'قم بتأكيد هويتك لتسجيل الدخول السريع',
    );

    if (authenticated) {
      final creds = await _biometricService.getCredentials();
      if (creds != null) {
        setState(() => _isLoading = true);

        bool hasInternet = await ConnectivityHelper.hasInternetConnection();
        if (!hasInternet) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
                ),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        try {
          final user = await AuthService().signInWithEmailAndPassword(
            creds['email']!,
            creds['password']!,
          );

          if (mounted) {
            setState(() => _isLoading = false);
            if (user != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => RootScreen()),
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'فشل تسجيل الدخول. قد تكون بياناتك قديمة، يرجى الدخول بكلمة المرور مجدداً.',
                  ),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
          }
        }
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool hasInternet = await ConnectivityHelper.hasInternetConnection();
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.'),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await AuthService().signInWithEmailAndPassword(
        _identifierController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          if (_enableBiometricForFuture) {
            await _biometricService.saveCredentials(
              _identifierController.text.trim(),
              _passwordController.text,
            );
          } else if (!_canUseBiometric) {
            // Optional: If they unchecked it and we wanted to clear it. For now, leave it alone or clear it.
          }

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => RootScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تسجيل الدخول. تأكد من صحة البيانات.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative Blobs
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.5),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.sports_esports,
                              size: 48,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'سودان إي سبورت',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'بوابتك للبطولات الوطنية',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    // Glassmorphism Form Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 24),
                                _buildModernTextField(
                                  controller: _identifierController,
                                  label: 'البريد الإلكتروني',
                                  hint: 'أدخل البريد الإلكتروني (مثل: admin@esportsudan.sd)',
                                  icon: Icons.alternate_email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.validateEmail,
                                ),
                                SizedBox(height: 20),
                                _buildModernTextField(
                                  controller: _passwordController,
                                  label: 'كلمة المرور',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: Validators.validatePassword,
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: _showForgotPasswordDialog,
                                      child: Text(
                                        'نسيت كلمة المرور؟',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'تذكرني',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                        Checkbox(
                                          value: _rememberMe,
                                          onChanged: (val) => setState(
                                            () => _rememberMe = val ?? false,
                                          ),
                                          activeColor: AppTheme.primaryBlue,
                                          checkColor: Colors.black,
                                          side: BorderSide(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (_isBiometricSupported && !_canUseBiometric)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'الدخول بالبصمة مستقبلاً',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      Checkbox(
                                        value: _enableBiometricForFuture,
                                        onChanged: (val) => setState(
                                          () => _enableBiometricForFuture =
                                              val ?? false,
                                        ),
                                        activeColor: AppTheme.primaryBlue,
                                        checkColor: Colors.black,
                                        side: BorderSide(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModernButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        label: 'دخول الساحة',
                                        icon: Icons.login,
                                        isLoading: _isLoading,
                                        isPrimary: true,
                                      ),
                                    ),
                                    if (_canUseBiometric) ...[
                                      SizedBox(width: 16),
                                      Container(
                                        height:
                                            56, // matches button height roughly
                                        width: 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          color: Theme.of(context).colorScheme.onSurface.withValues(
                                            alpha: 0.1,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.primaryBlue
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.fingerprint,
                                            color: AppTheme.primaryBlue,
                                            size: 32,
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : _handleBiometricLogin,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'أو سجل بواسطة',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                _buildModernButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _handleGoogleSignIn,
                                  label: 'متابعة بـ Google',
                                  icon: Icons
                                      .g_mobiledata, // Or use a custom google icon
                                  iconSize: 32,
                                  isLoading: false,
                                  isPrimary: false,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MainScreen(isGuest: true),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.explore,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      label: Text(
                        'استكشف البطولات كزائر',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ليس لديك حساب؟ ',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'سجل الآن كلاعب رسمي',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && _obscurePassword,
          validator: validator,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          textDirection: isPassword ||
                  keyboardType == TextInputType.emailAddress ||
                  keyboardType == TextInputType.phone
              ? TextDirection.ltr
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primaryBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    bool isLoading = false,
    bool isPrimary = true,
    double iconSize = 24,
  }) {
    return Container(
      decoration: isPrimary
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryRed],
              ), // A bright green gradient
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            )
          : null,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(vertical: 18),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(icon, color: Colors.black, size: iconSize),
                      ],
                    ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: iconSize),
                ],
              ),
            ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'استعادة كلمة المرور',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أدخل بريدك الإلكتروني لإرسال رابط الاستعادة:',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'إلغاء',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogContext);
                  try {
                    await AuthService().sendPasswordResetEmail(email);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم إرسال رابط الاستعادة إلى بريدك الإلكتروني.',
                        ),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('حدث خطأ: $e')),
                    );
                  }
                }
              },
              child: Text('إرسال'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => RootScreen()),
            (route) => false,
          );
        } else {
          // User canceled or failed without throw
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تسجيل الدخول بـ Google: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
