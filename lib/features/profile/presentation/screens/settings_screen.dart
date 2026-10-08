import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/security_settings_screen.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/bank_accounts_screen.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/financial_transactions_screen.dart';
import 'package:url_launcher/url_launcher.dart';
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
      SnackBar(
        content: Text('هذه الميزة ستتوفر قريباً!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('مركز المساعدة والأسئلة الشائعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('س: كيف يمكنني سحب أرباحي؟', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Text('ج: من خلال قسم المحفظة، يمكنك طلب سحب الأرباح إلى حسابك البنكي المضاف، وتستغرق العملية من 1 إلى 3 أيام عمل.', style: TextStyle(fontSize: 13)),
              SizedBox(height: 12),
              Text('س: ما هي قوانين البطولات؟', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Text('ج: يمنع استخدام أي برامج غش (هاكات)، ويجب احترام مواعيد المباريات. سيتم استبعاد أي فريق يخالف القوانين مباشرة.', style: TextStyle(fontSize: 13)),
              SizedBox(height: 12),
              Text('س: كيف أسجل فريقي في بطولة؟', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Text('ج: ادخل لصفحة البطولة واضغط على "التسجيل في البطولة"، يجب أن يحتوي فريقك على العدد المطلوب وأن يكون لديك رصيد كافٍ.', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إغلاق')),
        ],
      ),
    );
  }

  void _showSupportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التواصل مع الدعم الفني', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('اختر وسيلة التواصل المناسبة لك للحصول على المساعدة:', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.facebook, color: Colors.blue, size: 36),
              title: Text('فيسبوك', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final url = Uri.parse('https://www.facebook.com/share/1HjaqDEnWm/?mibextid=wwXIfr');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: Colors.green, size: 36),
              title: Text('واتساب', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final url = Uri.parse('https://wa.me/249124177296?s=p');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.telegram, color: Colors.blueAccent, size: 36),
              title: Text('تيليجرام', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final url = Uri.parse('https://t.me/yamizoz');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showTermsAndConditions(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('الشروط والأحكام / الخصوصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. الخصوصية:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Text('نحن نحرص على حماية بياناتك الشخصية وحسابك البنكي ولن تتم مشاركتها مع أي جهة خارجية.', style: TextStyle(fontSize: 13)),
              SizedBox(height: 12),
              Text('2. البطولات والمحفظة:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Text('لا يمكن استرداد رسوم الاشتراك بعد بدء البطولة. عمليات سحب الأرباح تتطلب التأكد من هوية اللاعب وتستغرق بعض الوقت.', style: TextStyle(fontSize: 13)),
              SizedBox(height: 12),
              Text('3. قوانين المنصة:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              Text('يلتزم جميع اللاعبين بالروح الرياضية، وأي سلوك مسيء أو استخدام لبرامج غير قانونية سيعرض الحساب للحظر النهائي.', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('موافق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
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
                onTap: () async {
                  final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
                  if (res == true && mounted) {
                    _loadSettings();
                  }
                },
              ),
              _buildDivider(),
              _buildListTile(
                title: 'الأمان وكلمة المرور',
                subtitle: 'تغيير كلمة المرور، المصادقة الثنائية',
                icon: Icons.security,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SecuritySettingsScreen()));
                },
              ),
            ]),
            SizedBox(height: 20),


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
                  hideStatistics: _settings.hideStatistics,
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
                  hideStatistics: _settings.hideStatistics,
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
                  hideStatistics: _settings.hideStatistics,
                  language: _settings.language,
                )),
              ),
            ]),
            SizedBox(height: 20),

            // Wallet & Payments
            _buildSectionHeader('المحفظة والدفع', Icons.account_balance_wallet),
            _buildCardContainer([
              _buildListTile(
                title: 'طرق الدفع',
                subtitle: 'إدارة الحسابات البنكية (بنكك، فوري)',
                icon: Icons.payment,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BankAccountsScreen()));
                },
              ),
              _buildDivider(),
              _buildListTile(
                title: 'سجل المعاملات المالي',
                subtitle: 'عرض المبالغ المسحوبة والمودعة',
                icon: Icons.history,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FinancialTransactionsScreen()));
                },
              ),
            ]),
            SizedBox(height: 20),

            // Privacy
            _buildSectionHeader('الخصوصية', Icons.lock),
            _buildCardContainer([
              _buildSwitchTile(
                title: 'إخفاء الإحصائيات',
                subtitle: 'تحديد من يمكنه رؤية إحصائياتك',
                value: _settings.hideStatistics,
                onChanged: (val) => _updateSettings(UserSettings(
                  isDarkMode: _settings.isDarkMode,
                  dataSaver: _settings.dataSaver,
                  tournamentNotifs: _settings.tournamentNotifs,
                  matchReminders: _settings.matchReminders,
                  teamInvites: _settings.teamInvites,
                  hideStatistics: val,
                  language: _settings.language,
                )),
              ),
            ]),
            SizedBox(height: 20),

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
                  hideStatistics: _settings.hideStatistics,
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
                  hideStatistics: _settings.hideStatistics,
                  language: _settings.language,
                )),
              ),
              _buildDivider(),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.language, color: AppTheme.primaryBlue, size: 22),
                ),
                title: Text('لغة التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(_settings.language, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11)),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('قريباً في التحديث القادم')));
                    return;
                    final String? selectedLanguage = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: Text('اختر اللغة'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: Text('العربية'),
                              onTap: () => Navigator.pop(context, 'العربية'),
                            ),
                            ListTile(
                              title: Text('English'),
                              onTap: () => Navigator.pop(context, 'English'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  if (selectedLanguage != null && selectedLanguage != _settings.language) {
                    _updateSettings(UserSettings(
                      isDarkMode: _settings.isDarkMode,
                      dataSaver: _settings.dataSaver,
                      tournamentNotifs: _settings.tournamentNotifs,
                      matchReminders: _settings.matchReminders,
                      teamInvites: _settings.teamInvites,
                      hideStatistics: _settings.hideStatistics,
                      language: selectedLanguage,
                    ));
                  }
                },
              ),
            ]),
            SizedBox(height: 20),

            // Support & About
            _buildSectionHeader('الدعم الفني والمعلومات', Icons.help_outline),
            _buildCardContainer([
              _buildListTile(
                title: 'مركز المساعدة والأسئلة الشائعة',
                subtitle: 'قوانين البطولات وطرق السحب',
                icon: Icons.question_answer,
                onTap: () => _showHelpCenter(context),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'التواصل مع الدعم الفني',
                subtitle: 'تواصل معنا لحل أي مشكلة فنية',
                icon: Icons.support_agent,
                onTap: () => _showSupportOptions(context),
              ),
              _buildDivider(),
              _buildListTile(
                title: 'الشروط والأحكام / الخصوصية',
                subtitle: 'اقرأ سياسات الاستخدام',
                icon: Icons.article,
                onTap: () => _showTermsAndConditions(context),
              ),
            ]),
            SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                await AuthService().signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: Icon(Icons.logout, color: Colors.red),
              label: Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, right: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 20),
          SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10), height: 1, indent: 56);
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11)),
      value: value,
      activeThumbColor: AppTheme.primaryBlue,
      onChanged: onChanged,
    );
  }
}
