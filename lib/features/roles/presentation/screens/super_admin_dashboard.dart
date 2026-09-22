import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/deposit_requests_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_dashboard.dart';
import 'referee_dashboard.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_management_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  String _searchQuery = '';

  Map<String, dynamic>? _metrics;
  bool _isLoadingMetrics = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final metrics = await FirestoreService().getDashboardMetrics();
    if (mounted) {
      setState(() {
        _metrics = metrics;
        _isLoadingMetrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة الإدارة العليا (Super Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.primaryBlue),
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
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.security, color: AppTheme.primaryBlue, size: 28),
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
                    decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
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
                _buildMetricBox('اللاعبين المسجلين', '${_metrics?['usersCount'] ?? 0}', Icons.person, AppTheme.primaryBlue),
                const SizedBox(width: 10),
                _buildMetricBox('الفرق المعتمدة', '${_metrics?['teamsCount'] ?? 0} فريق', Icons.shield, Colors.blue),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricBox('البطولات القومية', '${_metrics?['tournamentsCount'] ?? 0} بطولات', Icons.emoji_events, Colors.orange),
                const SizedBox(width: 10),
                _buildMetricBox('إجمالي الإيداعات', '${_metrics?['totalFees'] ?? 0} ج.س', Icons.account_balance_wallet, Colors.amber),
              ],
            ),
            const SizedBox(height: 24),

            // Deposit Requests Tile
            ListTile(
              tileColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.account_balance, color: AppTheme.primaryBlue),
              title: const Text('مراجعة طلبات شحن الرصيد', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DepositRequestsScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // User Role Management
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إدارة صلاحيات المستخدمين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'بحث وترقية',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue.withOpacity(0.8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المستخدم (مثال: Ahmed)...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService().searchAllUsersStream(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                  }
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text('لم يتم العثور على مستخدمين بهذا الاسم', style: TextStyle(color: Colors.white54)),
                      ),
                    );
                  }
                  return Column(
                    children: users.map((user) => _buildUserSearchTile(context, user)).toList(),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text('اكتب اسم المستخدم للبحث وترقية حسابه', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ),
              ),
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
                leading: const Icon(Icons.groups, color: AppTheme.primaryBlue),
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

  Widget _buildUserSearchTile(BuildContext context, Map<String, dynamic> user) {
    final role = user['role'] ?? 'player';
    final name = user['displayName'] ?? 'مستخدم بدون اسم';
    final email = user['email'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
            child: const Icon(Icons.person, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showRoleChangeBottomSheet(context, user),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: AppTheme.primaryBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('الدور: $role', style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeBottomSheet(BuildContext context, Map<String, dynamic> user) {
    final currentRole = user['role'] ?? 'player';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تغيير صلاحيات: ${user['displayName']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('اختر الدور الجديد لهذا المستخدم. سيتم تطبيق الصلاحيات فوراً.', style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 16),
              _buildRoleOption(ctx, user['id'], 'super_admin', 'مدير نظام أعلى (Super Admin)', Icons.security, Colors.purple, currentRole),
              _buildRoleOption(ctx, user['id'], 'tournament_admin', 'منظم بطولات (Organizer)', Icons.emoji_events, Colors.orange, currentRole),
              _buildRoleOption(ctx, user['id'], 'referee', 'حكم معتمد (Referee)', Icons.sports, Colors.blue, currentRole),
              _buildRoleOption(ctx, user['id'], 'finance_admin', 'مسؤول مالي (Finance)', Icons.account_balance, Colors.teal, currentRole),
              _buildRoleOption(ctx, user['id'], 'player', 'لاعب عادي (Player)', Icons.person, AppTheme.primaryBlue, currentRole),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleOption(BuildContext context, String userId, String roleValue, String roleName, IconData icon, Color color, String currentRole) {
    final isSelected = currentRole == roleValue;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(roleName, style: TextStyle(color: isSelected ? color : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      onTap: () async {
        Navigator.pop(context);
        try {
          await FirestoreService().updateUserRole(userId, roleValue);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تغيير الصلاحية إلى $roleName بنجاح ✅', style: const TextStyle(color: Colors.black)),
                backgroundColor: AppTheme.primaryBlue,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فشل تغيير الصلاحية ❌'), backgroundColor: Colors.red),
            );
          }
        }
      },
    );
  }
}
