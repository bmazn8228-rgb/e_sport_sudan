import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/deposit_requests_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/tournament_admin_dashboard_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_complaints_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_teams_screen.dart';
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
            icon: const Icon(Icons.cloud_sync, color: AppTheme.primaryBlue),
            tooltip: 'لوحة تحكم البث والتهيئة',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white70),
            tooltip: 'تبديل الدور والواجهة',
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
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.2),
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
                        Text('السيادة الوطنية الكاملة والتحكم بكافة الجداول والصلاحيات', style: TextStyle(fontSize: 11, color: Colors.orange)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Server telemetry
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
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
                    child: Text('خوادم المنظومة الوطنية (نشطة 100%) • متصل بـ Firebase Cloud', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Telemetry Bento Grid (Interactive)
            const Text('إحصائيات المنظومة الوطنية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricBox('اللاعبين المسجلين', '${_metrics?['usersCount'] ?? 0}', Icons.person, AppTheme.primaryBlue, () {}),
                const SizedBox(width: 10),
                _buildMetricBox('الفرق المعتمدة', '${_metrics?['teamsCount'] ?? 0} فريق', Icons.shield, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerTeamsScreen()));
                }),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMetricBox('البطولات القومية', '${_metrics?['tournamentsCount'] ?? 0} بطولة', Icons.emoji_events, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TournamentAdminDashboardScreen()));
                }),
                const SizedBox(width: 10),
                _buildMetricBox('إجمالي الإيداعات', '${_metrics?['totalFees'] ?? 0} ج.س', Icons.account_balance_wallet, Colors.amber, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DepositRequestsScreen()));
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Portals & Hub Actions
            const Text('بوابات الإدارة المباشرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance, color: Colors.greenAccent),
                    title: const Text('مراجعة طلبات شحن الرصيد والإيداعات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('اعتماد إشعارات بنكك وفوري وإيداع الأرصدة في المحافظ', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DepositRequestsScreen())),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: const Icon(Icons.emoji_events, color: Colors.amber),
                    title: const Text('لوحة إدارة وإنشاء البطولات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('إضافة بطولات جديدة، تعديل الحالات، وحذف البطولات', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TournamentAdminDashboardScreen())),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: const Icon(Icons.live_tv, color: Colors.redAccent),
                    title: const Text('إدارة البث المباشر والتهيئة السحابية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('ربط بث YouTube Live مع التطبيق وتهيئة الجداول السحابية', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrangeAccent),
                    title: const Text('الاعتراضات والشكاوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('متابعة شكاوى الفرق واللاعبين وحلها في النظام', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerComplaintsScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Role Management
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إدارة المستخدمين والصلاحيات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'بحث وترقية فورية',
                  style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue.withValues(alpha: 0.8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث باسم المستخدم أو البريد الإلكتروني...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getAllUsersStream(limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }
                var users = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  users = users.where((u) {
                    final name = (u['displayName'] ?? '').toString().toLowerCase();
                    final email = (u['email'] ?? '').toString().toLowerCase();
                    final role = (u['role'] ?? '').toString().toLowerCase();
                    return name.contains(q) || email.contains(q) || role.contains(q);
                  }).toList();
                }

                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text('لم يتم العثور على مستخدمين بهذا الاسم أو البريد', style: TextStyle(color: Colors.white54)),
                    ),
                  );
                }

                return Column(
                  children: users.map((user) => _buildUserSearchTile(context, user)).toList(),
                );
              },
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
              const Text('تبديل وضع العرض والمعاينة للوحة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                leading: const Icon(Icons.account_balance, color: Colors.greenAccent),
                title: const Text('مراجعة طلبات الإيداع (Finance Admin)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DepositRequestsScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_sync, color: AppTheme.primaryBlue),
                title: const Text('لوحة تحكم البث وقاعدة البيانات السحابية'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups, color: Colors.cyanAccent),
                title: const Text('إدارة الفرق والتشكيلات (Team Management)'),
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

  Widget _buildMetricBox(String title, String val, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 20, color: color),
                  const Icon(Icons.arrow_forward, size: 12, color: Colors.white24),
                ],
              ),
              const SizedBox(height: 8),
              Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSearchTile(BuildContext context, Map<String, dynamic> user) {
    final role = user['role'] ?? 'player';
    final name = user['displayName'] ?? 'مستخدم بدون اسم';
    final email = user['email'] ?? '';

    Color roleColor = AppTheme.primaryBlue;
    if (role == 'super_admin') roleColor = Colors.purpleAccent;
    if (role == 'tournament_admin') roleColor = Colors.orange;
    if (role == 'referee') roleColor = Colors.blue;
    if (role == 'finance_admin') roleColor = Colors.teal;

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
            backgroundColor: roleColor.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: roleColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(email.isNotEmpty ? email : 'لا يوجد بريد مسجل', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showRoleChangeBottomSheet(context, user),
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor.withValues(alpha: 0.15),
              foregroundColor: roleColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
              Text('تغيير صلاحيات: ${user['displayName'] ?? 'المستخدم'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('اختر الدور الجديد لهذا المستخدم. سيتم تحديث الصلاحية فوراً في Firebase.', style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 16),
              _buildRoleOption(ctx, user['id'], 'super_admin', 'مدير نظام أعلى (Super Admin)', Icons.security, Colors.purple, currentRole),
              _buildRoleOption(ctx, user['id'], 'tournament_admin', 'منظم بطولات (Tournament Admin)', Icons.emoji_events, Colors.orange, currentRole),
              _buildRoleOption(ctx, user['id'], 'referee', 'حكم معتمد (Referee)', Icons.sports, Colors.blue, currentRole),
              _buildRoleOption(ctx, user['id'], 'finance_admin', 'مسؤول مالي (Finance Admin)', Icons.account_balance, Colors.teal, currentRole),
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
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        try {
          await FirestoreService().updateUserRole(userId, roleValue);
          messenger.showSnackBar(
            SnackBar(
              content: Text('تم تغيير الصلاحية إلى $roleName بنجاح ✅', style: const TextStyle(color: Colors.black)),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text('فشل تغيير الصلاحية: $e ❌'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }
}
