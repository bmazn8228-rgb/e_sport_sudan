import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'organizer_dashboard.dart';
import 'referee_dashboard.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

  // This will be replaced with a Firestore stream in the future
  final List<Map<String, dynamic>> _pendingVerifications = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة الإدارة العليا (Super Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryGreen),
            tooltip: 'تبديل الدور',
            onPressed: () => _showRoleSwitcher(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Identity Ribbon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.security, color: AppTheme.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مدير النظام الأعلى • Super Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('النطاق: السيادة الوطنية الكاملة على المنصة', style: TextStyle(fontSize: 11, color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Server telemetry
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('خوادم الخرطوم وبورتسودان (99.9% نشطة) • مزامنة فورية', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Telemetry Bento Grid
            const Text('إحصائيات المنظومة الوطنية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricBox('اللاعبين المسجلين', '0', Icons.person, AppTheme.primaryGreen),
                const SizedBox(width: 10),
                _buildMetricBox('الفرق المعتمدة', '0 فريق', Icons.shield, Colors.blue),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricBox('البطولات القومية', '0 بطولات', Icons.emoji_events, Colors.orange),
                const SizedBox(width: 10),
                _buildMetricBox('رسوم التسجيل', '0 ج.س', Icons.account_balance_wallet, Colors.amber),
              ],
            ),
            const SizedBox(height: 24),

            // Verification Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('طلبات الاعتماد وتوثيق الرخص', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'تحديث فوري',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryGreen.withOpacity(0.8)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_pendingVerifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text('لا توجد طلبات اعتماد معلقة حالياً', style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              ..._pendingVerifications.map((req) => _buildVerificationTile(context, req)),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تبديل وضع العرض والمعاينة للدور:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                title: const Text('لوحة تحكم منظم البطولة (Organizer)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerDashboard()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.sports, color: Colors.blue),
                title: const Text('لوحة تحكم الحكم المعتمد (Referee)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RefereeDashboard()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups, color: AppTheme.primaryGreen),
                title: const Text('إدارة الفريق (Team Management)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamManagementScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricBox(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTile(BuildContext context, Map<String, dynamic> req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(req['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(req['requestedRole'], style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('الموقع: ${req['state']} • الخبرة: ${req['experience']}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم اعتماد وترقية: ${req['name']} بنجاح ✅', style: const TextStyle(color: Colors.black)),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                  child: const Text('اعتماد ومنح الصلاحية', style: TextStyle(fontSize: 11, color: Colors.black)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم رفض طلب (${req['name']}) وحذفه ❌', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('رفض', style: TextStyle(fontSize: 11, color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
