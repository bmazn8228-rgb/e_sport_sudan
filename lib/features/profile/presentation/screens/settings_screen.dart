import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/security_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserSettings _settings = UserSettings();
  bool _isLoading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        _uid = user.uid;
        final userModel = await FirestoreService().getUser(user.uid);
        if (userModel != null) {
          if (mounted) {
            setState(() {
              _settings = userModel.settings;
              _isLoading = false;
            });
          }
          // Sync topics initially on load just to be sure
          NotificationService().syncTopicSubscriptions(_settings);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSettings(UserSettings newSettings) async {
    setState(() => _settings = newSettings);
    if (_uid != null) {
      await FirestoreService().updateUserSettings(_uid!, newSettings);
      // Sync topics with Firebase Cloud Messaging
      NotificationService().syncTopicSubscriptions(newSettings);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذه الميزة ستتوفر قريباً!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            _buildSectionHeader('إعدادات الحساب الشخصي', Icons.person),
            _buildCardContainer([
              _buildListTile(
                title: 'تعديل الملف الشخصي',
                subtitle: 'تغيير الاسم، الصورة، واسم اللاعب',
                icon: Icons.edit,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                },
              ),
              _buildDivider(),
              _buildListTile(
                title: 'الأمان وكلمة المرور',
                subtitle: 'تغيير كلمة المرور، المصادقة الثنائية',
                icon: Icons.security,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
                },
              ),
            ]),
            const SizedBox(height: 20),

            // Gaming Preferences
            _buildSectionHeader('تفضيلات الألعاب والبطولات', Icons.sports_esports),
            _buildCardContainer([
              _buildListTile(
                title: 'الألعاب المفضلة',
                subtitle: 'تخصيص البطولات والأخبار حسب ألعابك',
                icon: Icons.gamepad,
                onTap: _showComingSoon,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'تفضيلات شجرة المباريات',
                subtitle: 'طريقة عرض النتائج والمواجهات',
                icon: Icons.account_tree,
                onTap: _showComingSoon,
              ),
            ]),
            const SizedBox(height: 20),

            // Notifications
            _buildSectionHeader('الإشعارات والتنبيهات', Icons.notifications),
            _buildCardContainer([
              _buildSwitchTile(
                title: 'إشعارات البطولات',
                subtitle: 'تنبيه عند فتح التسجيل لبطولات جديدة',
                value: _settings.tournamentNotifs,
                onChanged: (val) => _updateSettings(UserSettings(
                  isDarkMode: _settings.isDarkMode,
                  dataSaver: _settings.dataSaver,
                  tournamentNotifs: val,
                  matchReminders: _settings.matchReminders,
                  teamInvites: _settings.teamInvites,
                  language: _settings.language,
                )),
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'تذكير المباريات',
                subtitle: 'تنبيه قبل بدء المباريات بـ 15 دقيقة',
                value: _settings.matchReminders,
                onChanged: (val) => _updateSettings(UserSettings(
                  isDarkMode: _settings.isDarkMode,
                  dataSaver: _settings.dataSaver,
                  tournamentNotifs: _settings.tournamentNotifs,
                  matchReminders: val,
                  teamInvites: _settings.teamInvites,
                  language: _settings.language,
                )),
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'إشعارات ودعوات الفرق',
                subtitle: 'استقبال دعوات الانضمام ورسائل الفرق',
                value: _settings.teamInvites,
                onChanged: (val) => _updateSettings(UserSettings(
                  isDarkMode: _settings.isDarkMode,
                  dataSaver: _settings.dataSaver,
                  tournamentNotifs: _settings.tournamentNotifs,
                  matchReminders: _settings.matchReminders,
                  teamInvites: val,
                  language: _settings.language,
                )),
              ),
            ]),
            const SizedBox(height: 20),

            // Wallet & Payments
            _buildSectionHeader('المحفظة والدفع', Icons.account_balance_wallet),
            _buildCardContainer([
              _buildListTile(
                title: 'طرق الدفع',
                subtitle: 'إدارة الحسابات البنكية (بنكك، فوري)',
                icon: Icons.payment,
                onTap: _showComingSoon,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'سجل المعاملات المالي',
                subtitle: 'عرض المبالغ المسحوبة والمودعة',
                icon: Icons.history,
                onTap: _showComingSoon,
              ),
            ]),
            const SizedBox(height: 20),

            // Privacy
            _buildSectionHeader('الخصوصية', Icons.lock),
            _buildCardContainer([
              _buildListTile(
                title: 'إخفاء الإحصائيات',
                subtitle: 'تحديد من يمكنه رؤية إحصائياتك',
                icon: Icons.visibility_off,
                onTap: _showComingSoon,
              ),
            ]),
            const SizedBox(height: 20),

            // App Preferences
            _buildSectionHeader('تفضيلات التطبيق', Icons.settings_applications),
            _buildCardContainer([
              _buildSwitchTile(
                title: 'الوضع الداكن (Dark Mode)',
                subtitle: 'تغيير مظهر التطبيق',
                value: _settings.isDarkMode,
                onChanged: (val) => _updateSettings(UserSettings(
                  isDarkMode: val,
                  dataSaver: _settings.dataSaver,
                  tournamentNotifs: _settings.tournamentNotifs,
                  matchReminders: _settings.matchReminders,
                  teamInvites: _settings.teamInvites,
                  language: _settings.language,
                )),
              ),
              _buildDivider(),
              _buildSwitchTile(
                title: 'توفير البيانات (Data Saver)',
                subtitle: 'تقليل جودة البث للحفاظ على الإنترنت',
                value: _settings.dataSaver,
                onChanged: (val) => _updateSettings(UserSettings(
                  isDarkMode: _settings.isDarkMode,
                  dataSaver: val,
                  tournamentNotifs: _settings.tournamentNotifs,
                  matchReminders: _settings.matchReminders,
                  teamInvites: _settings.teamInvites,
                  language: _settings.language,
                )),
              ),
              _buildDivider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language, color: AppTheme.primaryBlue, size: 22),
                ),
                title: const Text('لغة التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(_settings.language, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                onTap: _showComingSoon,
              ),
            ]),
            const SizedBox(height: 20),

            // Support & About
            _buildSectionHeader('الدعم الفني والمعلومات', Icons.help_outline),
            _buildCardContainer([
              _buildListTile(
                title: 'مركز المساعدة والأسئلة الشائعة',
                subtitle: 'قوانين البطولات وطرق السحب',
                icon: Icons.question_answer,
                onTap: _showComingSoon,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'التواصل مع الدعم الفني',
                subtitle: 'رفع تذكرة لمشكلة فنية',
                icon: Icons.support_agent,
                onTap: _showComingSoon,
              ),
              _buildDivider(),
              _buildListTile(
                title: 'الشروط والأحكام / الخصوصية',
                subtitle: 'اقرأ سياسات الاستخدام',
                icon: Icons.article,
                onTap: _showComingSoon,
              ),
            ]),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                await AuthService().signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white10, height: 1, indent: 56);
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      value: value,
      activeThumbColor: AppTheme.primaryBlue,
      onChanged: onChanged,
    );
  }
}
