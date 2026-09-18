import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  UserRole _activeRole = UserRole.superAdmin;
  bool _isSeeding = false;
  String? _statusMessage;

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = null;
    });

    try {
      await FirestoreService().seedInitialData();
      setState(() {
        _isSeeding = false;
        _statusMessage = 'تمت تهيئة الجداول وحسابات الأدمن والبيانات الأولية بنجاح! ✅';
      });
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _statusMessage = 'تنبيه: يتطلب الاتصال المباشر بـ Firebase وجود ملف google-services.json الحقيقي.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة تحكم الإدارة والصلاحيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Role Badge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الدور الحالي المُحدد للتجربة:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeRole.displayNameArabic,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _activeRole.toValue().toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('اختر دوراً لمعاينة صلاحياته والعمليات المسموحة له:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: UserRole.values.map((role) {
                      final isSelected = role == _activeRole;
                      return ChoiceChip(
                        label: Text(role.displayNameArabic, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: Colors.white10,
                        onSelected: (_) => setState(() => _activeRole = role),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // One-Click Database Seeding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.cloud_upload_outlined, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('تهيئة الجداول السحابية (One-Click Seed)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'زر بنقرة واحدة لإنشاء وتعبئة جميع الجداول تلقائياً في Firebase (البطولات، الفرق، إحصائيات PUBG و EA FC، وحسابات الأدمن).',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: Text(_statusMessage!, style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _seedDatabase,
                      icon: _isSeeding
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.flash_on, color: Colors.black),
                      label: Text(
                        _isSeeding ? 'جاري تهيئة الجداول...' : 'إنشاء وتعبئة الجداول الآن 🚀',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Role-Specific Action Cards
            const Text('العمليات والصلاحيات المتاحة لهذا الدور:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),

            ..._buildRoleActions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoleActions() {
    switch (_activeRole) {
      case UserRole.superAdmin:
        return [
          _buildActionCard('إدارة كافة الحسابات والأدوار', 'تحديد وتغيير رتب المستخدمين ومنح صلاحيات الأدمن', Icons.admin_panel_settings, Colors.purple),
          _buildActionCard('إدارة قواعد الأمان (Security Rules)', 'تطبيق سياسات Firestore والحماية الشاملة', Icons.security, Colors.blue),
          _buildActionCard('الوصول المالي والبطولات الكامل', 'صلاحيات مطلقة للتعديل والحذف لكافة الجداول', Icons.all_inclusive, AppTheme.primaryGreen),
        ];

      case UserRole.tournamentAdmin:
        return [
          _buildActionCard('إنشاء وإدارة البطولات', 'تحديد رسوم الاشتراك، الجوائز، والتواريخ في جدول tournaments', Icons.emoji_events, Colors.amber),
          _buildActionCard('اعتماد تسجيل الفرق', 'مراجعة طلبات الانضمام للبطولات وإنشاء شجرة المواجهات (Brackets)', Icons.groups, Colors.teal),
          _buildActionCard('تحديث إحصائيات الألعاب', 'تعديل جدول rankings و game_stats لكل لعبة بشكل منفصل', Icons.bar_chart, Colors.orange),
        ];

      case UserRole.referee:
        return [
          _buildActionCard('التحكم في نتائج المباريات المباشرة', 'تعديل النتيجة الحية وحالة المباراة (مباشر / انتهت)', Icons.sports_score, Colors.lightBlue),
          _buildActionCard('إدارة رابط البث المباشر (YouTube)', 'تحديث معرف أو رابط فيديو البث المباشر', Icons.live_tv, Colors.red),
          _buildActionCard('الإشراف على الدردشة المباشرة (Chat)', 'حظر المستخدمين المسيئين وحذف التعليقات المخالفة', Icons.chat_bubble_outline, Colors.pink),
        ];

      case UserRole.financeAdmin:
        return [
          _buildActionCard('مراجعة إشعارات التحويل (بنكك / فوري)', 'فحص صور الإشعارات في جدول transactions وقبولها', Icons.receipt_long, Colors.green),
          _buildActionCard('إيداع الأرصدة في محافظ اللاعبين', 'تحديث رصيد جدول wallets عند نجاح التحويل', Icons.account_balance_wallet, Colors.teal),
          _buildActionCard('صرف جوائز البطولات', 'تسليم الجوائز المالية للفائزين بعد انتهاء البطولة', Icons.payments, Colors.amber),
        ];

      case UserRole.player:
        return [
          _buildActionCard('إنشاء وإدارة الفريق الخاص', 'تعديل بيانات فريقه وإضافة اللاعبين واللوقو', Icons.group_add, Colors.blue),
          _buildActionCard('التسجيل في البطولات وشحن الرصيد', 'دفع الرسوم عبر المحفظة وإرفاق إشعار التحويل', Icons.sports_esports, AppTheme.primaryGreen),
          _buildActionCard('المشاركة في الدردشة وتصفح التصنيفات', 'متابعة البث الحي والتعليق ورؤية الترتيب العام', Icons.chat, Colors.cyan),
        ];
    }
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
