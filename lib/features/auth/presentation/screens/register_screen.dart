import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/utils/connectivity_helper.dart';
import 'package:e_sport_sudan/core/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'player'; // 'player' or 'spectator'
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ignController = TextEditingController(); // In-Game Name
  final _passwordController = TextEditingController();
  String? _selectedState;
  String? _selectedGame;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _sudanStates = [
    'الخرطوم',
    'الجزيرة',
    'البحر الأحمر',
    'كسلا',
    'القضارف',
    'نهر النيل',
    'الشمالية',
    'شمال كردفان',
    'جنوب كردفان',
    'غرب كردفان',
    'شمال دارفور',
    'جنوب دارفور',
    'غرب دارفور',
    'شرق دارفور',
    'وسط دارفور',
    'سنار',
    'النيل الأبيض',
    'النيل الأزرق',
  ];

  final List<String> _popularGames = [
    'PUBG Mobile',
    'EA FC 25 (FIFA)',
    'Free Fire',
    'Valorant',
    'Call of Duty Mobile',
    'Mobile Legends',
  ];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool hasNet = await ConnectivityHelper.hasInternetConnection();
    if (!hasNet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى التأكد من توفر اتصال بالإنترنت لإتمام التسجيل')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await AuthService().registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        ign: _selectedRole == 'player' ? _ignController.text.trim() : null,
        gameId: _selectedRole == 'player' ? _selectedGame : null,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null || AuthService().currentUser != null) {
          final registeredEmail = _emailController.text.trim();

          // تسجيل الخروج لتأكيد الدخول اليدوي من قبل المستخدم
          await AuthService().signOut();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الحساب بنجاح! يرجى تسجيل الدخول ببياناتك الجديدة 🎉'),
              backgroundColor: AppTheme.primaryBlue,
              duration: Duration(seconds: 4),
            ),
          );

          // التوجيه فوراً إلى شاشة تسجيل الدخول مع تعبئة البريد تلقائياً
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                prefilledEmail: registeredEmail,
              ),
            ),
            (route) => false,
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: const Text('فشل التسجيل', style: TextStyle(color: Colors.red)),
              content: const Text('حدث خطأ ولم يتم إنشاء الحساب. يرجى المحاولة مرة أخرى.', style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً', style: TextStyle(color: AppTheme.primaryBlue))),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // إذا كان الحساب قد أُنشئ بالفعل في Firebase رغم الاستثناء الجانبي
        if (AuthService().currentUser != null) {
          final registeredEmail = _emailController.text.trim();
          await AuthService().signOut();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء الحساب بنجاح! يرجى تسجيل الدخول ببياناتك الجديدة 🎉'),
              backgroundColor: AppTheme.primaryBlue,
              duration: Duration(seconds: 4),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                prefilledEmail: registeredEmail,
              ),
            ),
            (route) => false,
          );
          return;
        }

        String errorMessage = 'حدث خطأ أثناء إنشاء الحساب. يرجى المحاولة لاحقاً.';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل بحساب آخر.';
              break;
            case 'weak-password':
              errorMessage = 'كلمة المرور ضعيفة جداً. يجب أن تكون 6 خانات على الأقل.';
              break;
            case 'invalid-email':
              errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
              break;
            case 'network-request-failed':
              errorMessage = 'تعذر الاتصال بالشبكة. يرجى التأكد من اتصال الإنترنت.';
              break;
            default:
              errorMessage = e.message ?? errorMessage;
          }
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text('تنبيه التسجيل', style: TextStyle(color: Colors.redAccent)),
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً', style: TextStyle(color: AppTheme.primaryBlue))),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Decorative Blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'تسجيل حساب جديد',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أنشئ حسابك الرسمي المعتمد للحصول على رخصتك التنافسية لتمثيل السودان.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphism Form Container
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: -5),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Role Selector
                              const Text('المسار التنافسي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildRoleSelector('player', 'لاعب منافس', Icons.sports_esports)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildRoleSelector('spectator', 'مشاهد ومتابع', Icons.visibility)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: const Text(
                                        'صلاحيات التنظيم، التحكيم، وإدارة الفرق تعتمد بعد التحقق من الهوية.',
                                        style: TextStyle(fontSize: 12, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Form Fields
                              _buildModernTextField(
                                controller: _fullNameController,
                                label: 'الاسم الكامل (كما بالهوية)',
                                hint: 'مثال: أحمد عثمان علي',
                                icon: Icons.badge_outlined,
                                validator: (v) => Validators.validateName(v, fieldName: 'الاسم بالكامل'),
                              ),
                              const SizedBox(height: 20),

                              _buildModernTextField(
                                controller: _phoneController,
                                label: 'رقم الهاتف للتواصل',
                                hint: '+249912345678',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: Validators.validateSudanPhone,
                              ),
                              const SizedBox(height: 20),

                              _buildModernTextField(
                                controller: _emailController,
                                label: 'البريد الإلكتروني',
                                hint: 'example@email.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.validateEmail,
                              ),
                              const SizedBox(height: 20),

                              if (_selectedRole == 'player') ...[
                                _buildModernTextField(
                                  controller: _ignController,
                                  label: 'الاسم داخل اللعبة (In-Game Name)',
                                  hint: 'مثال: SUDAN_NINJA',
                                  icon: Icons.gamepad_outlined,
                                  validator: (v) => Validators.validateName(v, fieldName: 'الاسم داخل اللعبة'),
                                ),
                                const SizedBox(height: 20),
                                const Text('اللعبة المفضلة / الأساسية', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                _buildModernDropdown(
                                  value: _selectedGame,
                                  hint: 'اختر اللعبة',
                                  icon: Icons.sports_esports,
                                  items: _popularGames,
                                  onChanged: (val) => setState(() => _selectedGame = val),
                                ),
                                const SizedBox(height: 20),
                              ],

                              const Text('الولاية / المدينة', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              _buildModernDropdown(
                                value: _selectedState,
                                hint: 'اختر الولاية',
                                icon: Icons.location_on_outlined,
                                items: _sudanStates,
                                onChanged: (val) => setState(() => _selectedState = val),
                              ),
                              const SizedBox(height: 20),

                              _buildModernTextField(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                hint: '*******',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 32),

                              _buildModernButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                label: 'إتمام التسجيل وإصدار البطاقة',
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لديك حساب لاعب مسجل بالفعل؟ ', style: TextStyle(color: Colors.white70)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(String role, String title, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
          if (role == 'spectator') _ignController.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.white.withValues(alpha: 0.1)),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white70, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && _obscurePassword,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          textDirection: isPassword || keyboardType == TextInputType.phone || keyboardType == TextInputType.emailAddress 
              ? TextDirection.ltr 
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
            prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14)),
      dropdownColor: const Color(0xFF1E293B), // Dark slate
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
      validator: (v) => v == null ? 'الرجاء اختيار خيار' : null,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback? onPressed,
    required String label,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryRed]),
        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ignController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
