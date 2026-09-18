import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_management_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/referee_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/super_admin_dashboard.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImageFileName;
  bool _isCardFlipped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الملف الشخصي والبطاقة التنافسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // National Digital Player Card (بطاقة اللاعب الوطنية)
            GestureDetector(
              onTap: () => setState(() => _isCardFlipped = !_isCardFlipped),
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: _isCardFlipped ? 180 : 0),
                duration: const Duration(milliseconds: 500),
                builder: (BuildContext context, double val, Widget? child) {
                  bool isFront = val < 90;
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(val * 3.1415926535897932 / 180),
                    alignment: Alignment.center,
                    child: isFront
                        ? _buildFrontCard()
                        : Transform(
                            transform: Matrix4.identity()..rotateY(3.1415926535897932), // Fix mirror effect
                            alignment: Alignment.center,
                            child: _buildBackCard(),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. Stats & Tiers
            _buildStatsRow(),
            const SizedBox(height: 20),
            
            // 3. Trophy Cabinet (Badges)
            _buildTrophyCabinet(),
            const SizedBox(height: 20),
            
            // 4. Match History
            _buildMatchHistory(),
            const SizedBox(height: 20),

            // Wallet Portal
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
                  const Text('الخدمات المالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _buildPortalTile(
                    title: 'محفظة اللاعب (المحفظة الإلكترونية)',
                    subtitle: 'إدارة الرصيد، الشحن، وسحب الأرباح',
                    icon: Icons.account_balance_wallet,
                    color: AppTheme.primaryGreen,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Administrative Control Portals (حسب الصلاحيات)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بوابات إدارة النظام والصلاحيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _buildPortalTile(
                    title: 'إدارة الفريق والتشكيلة',
                    subtitle: 'صقور النيل • 5 لاعبين',
                    icon: Icons.groups,
                    color: AppTheme.primaryGreen,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamManagementScreen())),
                  ),
                  const Divider(color: Colors.white10),
                  _buildPortalTile(
                    title: 'لوحة تحكم منظم البطولة',
                    subtitle: 'إدارة المجموعات والقرعة التلقائية',
                    icon: Icons.admin_panel_settings,
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerDashboard())),
                  ),
                  const Divider(color: Colors.white10),
                  _buildPortalTile(
                    title: 'لوحة تحكم الحكم المعتمد',
                    subtitle: 'إدخال النتائج وتوثيق النزاهة',
                    icon: Icons.sports,
                    color: Colors.blue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RefereeDashboard())),
                  ),
                  const Divider(color: Colors.white10),
                  _buildPortalTile(
                    title: 'لوحة المشرف العام (Super Admin)',
                    subtitle: 'السيادة الوطنية واعتماد الرخص والحكام',
                    icon: Icons.security,
                    color: Colors.amber,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SuperAdminDashboard())),
                  ),
                  const Divider(color: Colors.white10),
                  _buildPortalTile(
                    title: 'إدارة الصلاحيات وقاعدة البيانات السحابية ☁️',
                    subtitle: 'فحص صلاحيات الأدوار وتهيئة جداول Firebase بنقرة واحدة',
                    icon: Icons.cloud_sync,
                    color: Colors.cyanAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: AppTheme.primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('مهند طارق (Falcon)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('صقور النيل • الخرطوم', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('بطاقة الهوية الرقمية 🇸🇩', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('E-SPORT SUDAN', style: TextStyle(color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('معرف اللاعب (Player ID)', style: TextStyle(color: Colors.white38, fontSize: 9)),
                  Text('SD-99214-SDN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('التقييم الوطني', style: TextStyle(color: Colors.white38, fontSize: 9)),
                  Text('1,420 نقطة', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('المستوى: محترف (Pro)', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('انقر للقلب 🔄 QR', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // QR Code representation
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2, size: 110, color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('رمز التحقق السريع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                SizedBox(height: 6),
                Text('امسح الرمز للتحقق من هوية اللاعب وصلاحية تسجيله في بطولات الاتحاد.', style: TextStyle(color: Colors.white54, fontSize: 10)),
                SizedBox(height: 10),
                Text('معتمد رسمياً 🇸🇩', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                Text('انقر للعودة للواجهة 🔄', style: TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- New Profile Components ---

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('البطولات', '12', Icons.emoji_events, Colors.amber),
          _buildStatColumn('الفوز', '68%', Icons.trending_up, AppTheme.primaryGreen),
          _buildStatColumn('الأرباح', '45K', Icons.monetization_on, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildTrophyCabinet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('خزانة الإنجازات (Badges)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildBadge(Icons.workspace_premium, 'بطل السودان 2025', Colors.amber),
              const SizedBox(width: 12),
              _buildBadge(Icons.my_location, 'قناص خطير', Colors.redAccent),
              const SizedBox(width: 12),
              _buildBadge(Icons.event_seat, 'لاعب أوفلاين', Colors.blue),
              const SizedBox(width: 12),
              _buildBadge(Icons.star, 'مؤسس مبكر', AppTheme.primaryGreen),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMatchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('سجل المباريات (Match History)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('عرض الكل', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildMatchHistoryItem(true, 'صقور النيل vs أبطال مدني', '2 - 1', 'اليوم'),
              const Divider(color: Colors.white10, height: 1),
              _buildMatchHistoryItem(false, 'صقور النيل vs ذئاب بورتسودان', '0 - 2', 'أمس'),
              const Divider(color: Colors.white10, height: 1),
              _buildMatchHistoryItem(true, 'صقور النيل vs أسود توتي', '1 - 0', 'منذ 3 أيام'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchHistoryItem(bool isWin, String teams, String score, String date) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isWin ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(isWin ? 'W' : 'L', style: TextStyle(color: isWin ? AppTheme.primaryGreen : Colors.red, fontWeight: FontWeight.bold)),
      ),
      title: Text(teams, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: Text(score, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildPortalTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
      onTap: onTap,
    );
  }
}
