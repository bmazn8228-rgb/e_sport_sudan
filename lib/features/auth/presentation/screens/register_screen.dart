import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/utils/connectivity_helper.dart';
import 'package:e_sport_sudan/core/utils/validators.dart';
import 'package:e_sport_sudan/features/main/presentation/screens/main_screen.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/features/main/presentation/screens/root_screen.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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
  String _selectedState = 'الخرطوم';
  String _selectedGame = 'PUBG Mobile';
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
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.primaryGreen,
              content: Text(
                'تم تسجيل الحساب وإصدار البطاقة الرقمية بنجاح! مرحباً بك في الساحة.',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RootScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل التسجيل. حاول مرة أخرى.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('تسجيل حساب جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'انضم لكتيبة المحترفين',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('موسم 2025', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'أنشئ حسابك الرسمي المعتمد في المنظومة الوطنية للرياضات الإلكترونية واحصل على رخصتك التنافسية لتمثيل السودان.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Role Selector
                const Text('نوع الحساب والمسار التنافسي', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'player'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'player' ? AppTheme.primaryGreen : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.sports_esports, color: _selectedRole == 'player' ? Colors.black : Colors.white),
                              const SizedBox(height: 4),
                              Text('لاعب منافس', style: TextStyle(color: _selectedRole == 'player' ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRole = 'spectator'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'spectator' ? AppTheme.primaryGreen : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.visibility, color: _selectedRole == 'spectator' ? Colors.black : Colors.white),
                              const SizedBox(height: 4),
                              Text('مشاهد ومتابع', style: TextStyle(color: _selectedRole == 'spectator' ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'صلاحيات التنظيم، التحكيم، وإدارة الفرق تعتمد بعد التحقق من الهوية.',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Fields
                const Text('الاسم الكامل (كما بالهوية)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  validator: (v) => Validators.validateName(v, fieldName: 'الاسم بالكامل'),
                  decoration: const InputDecoration(
                    hintText: 'مثال: أحمد عثمان علي',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('رقم الهاتف للتواصل'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validateSudanPhone,
                  decoration: const InputDecoration(
                    hintText: '+249912345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('البريد الإلكتروني'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                if (_selectedRole == 'player') ...[
                  const Text('الاسم داخل اللعبة (In-Game Name)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _ignController,
                    validator: (v) => Validators.validateName(v, fieldName: 'الاسم داخل اللعبة'),
                    decoration: const InputDecoration(
                      hintText: 'مثال: SUDAN_NINJA',
                      prefixIcon: Icon(Icons.gamepad_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('اللعبة المفضلة / الأساسية'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedGame,
                    items: _popularGames.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => setState(() => _selectedGame = val!),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.gamepad)),
                  ),
                  const SizedBox(height: 14),
                ],

                const Text('الولاية / المدينة'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  items: _sudanStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedState = val!),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.location_on_outlined)),
                ),
                const SizedBox(height: 14),

                const Text('كلمة المرور'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                  decoration: InputDecoration(
                    hintText: '*******',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : const Text('إتمام التسجيل وإصدار البطاقة'),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب لاعب مسجل بالفعل؟ '),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'تسجيل الدخول',
                        style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
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
