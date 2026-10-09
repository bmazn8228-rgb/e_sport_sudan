import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/deposit_requests_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/tournament_admin_dashboard_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_complaints_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_teams_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/admin_news_management_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/registered_players_screen.dart';
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
        title: Text('لوحة الإدارة العليا (Super Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_sync, color: AppTheme.primaryBlue),
            tooltip: 'لوحة تحكم البث والتهيئة',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboardScreen())),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            tooltip: 'تبديل الدور والواجهة',
            onPressed: () => _showRoleSwitcher(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Identity Ribbon
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                    child: Icon(Icons.security, color: AppTheme.primaryBlue, size: 28),
                  ),
                  SizedBox(width: 14),
                  Expanded(
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
            SizedBox(height: 14),

            // Server telemetry
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('خوادم المنظومة الوطنية (نشطة 100%) • متصل بـ Firebase Cloud', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Telemetry Bento Grid (Interactive)
            Text('إحصائيات المنظومة الوطنية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              children: [
                _buildMetricBox('اللاعبين المسجلين', '${_metrics?['usersCount'] ?? 0}', Icons.person, AppTheme.primaryBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisteredPlayersScreen()));
                }),
                SizedBox(width: 10),
                _buildMetricBox('الفرق المعتمدة', '${_metrics?['teamsCount'] ?? 0} فريق', Icons.shield, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerTeamsScreen()));
                }),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                _buildMetricBox('البطولات القومية', '${_metrics?['tournamentsCount'] ?? 0} بطولة', Icons.emoji_events, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentAdminDashboardScreen()));
                }),
                SizedBox(width: 10),
                _buildMetricBox('إجمالي الإيداعات', '${_metrics?['totalFees'] ?? 0} ج.س', Icons.account_balance_wallet, Colors.amber, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DepositRequestsScreen()));
                }),
              ],
            ),
            SizedBox(height: 24),

            // Portals & Hub Actions
            Text('بوابات الإدارة المباشرة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.people_alt_rounded, color: AppTheme.primaryBlue),
                    title: Text('دليل اللاعبين المسجلين ونظام الترقيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('عرض كافة اللاعبين المسجلين وترقية الصلاحيات وفق الهيكل الرتبي', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisteredPlayersScreen())),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: Icon(Icons.account_balance, color: Colors.greenAccent),
                    title: Text('مراجعة طلبات شحن الرصيد والإيداعات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('اعتماد إشعارات بنكك وفوري وإيداع الأرصدة في المحافظ', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DepositRequestsScreen())),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: Icon(Icons.newspaper, color: Colors.cyan),
                    title: Text('إدارة الأخبار والمقالات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('إضافة وتعديل أخبار وبلاغات الاتحاد', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminNewsManagementScreen())),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text('لوحة إدارة وإنشاء البطولات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('إضافة بطولات جديدة، تعديل الحالات، وحذف البطولات', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentAdminDashboardScreen())),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: Icon(Icons.live_tv, color: Colors.redAccent),
                    title: Text('إدارة البث المباشر والتهيئة السحابية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('ربط بث YouTube Live مع التطبيق وتهيئة الجداول السحابية', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboardScreen())),
                  ),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), height: 1),
                  ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.deepOrangeAccent),
                    title: Text('الاعتراضات والشكاوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('متابعة شكاوى الفرق واللاعبين وحلها في النظام', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerComplaintsScreen())),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // User Role Management
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إدارة المستخدمين والصلاحيات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisteredPlayersScreen())),
                  icon: Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.primaryBlue),
                  label: Text(
                    'عرض كل اللاعبين (${_metrics?['usersCount'] ?? ''})',
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، البريد الإلكتروني، أو آيدي التطبيق...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getAllUsersStream(limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }
                var users = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  users = users.where((u) {
                    final name = (u['displayName'] ?? '').toString().toLowerCase();
                    final email = (u['email'] ?? '').toString().toLowerCase();
                    final playerId = (u['playerId'] ?? '').toString().toLowerCase();
                    return name.contains(q) || email.contains(q) || playerId.contains(q);
                  }).toList();
                }

                if (users.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text('لم يتم العثور على مستخدمين بهذا الاسم أو البريد', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تبديل وضع العرض والمعاينة للوحة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.admin_panel_settings, color: Colors.orange),
                title: Text('لوحة تحكم منظم البطولة (Organizer)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerDashboard()));
                },
              ),
              ListTile(
                leading: Icon(Icons.sports, color: Colors.blue),
                title: Text('لوحة تحكم الحكم المعتمد (Referee)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RefereeDashboard()));
                },
              ),
              ListTile(
                leading: Icon(Icons.account_balance, color: Colors.greenAccent),
                title: Text('مراجعة طلبات الإيداع (Finance Admin)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DepositRequestsScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.cloud_sync, color: AppTheme.primaryBlue),
                title: Text('لوحة تحكم البث وقاعدة البيانات السحابية'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboardScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.groups, color: Colors.cyanAccent),
                title: Text('إدارة الفرق والتشكيلات (Team Management)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TeamManagementScreen()));
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
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 20, color: color),
                  Icon(Icons.arrow_forward, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                ],
              ),
              SizedBox(height: 8),
              Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
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
    final playerId = user['playerId'] ?? '';

    Color roleColor = AppTheme.primaryBlue;
    if (role == 'super_admin') roleColor = Colors.purpleAccent;
    if (role == 'tournament_admin') roleColor = Colors.orange;
    if (role == 'referee') roleColor = Colors.blue;
    if (role == 'finance_admin') roleColor = Colors.teal;

    return GestureDetector(
      onTap: () => _showRoleChangeBottomSheet(context, user),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: roleColor.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: roleColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (playerId.toString().isNotEmpty)
                    Text('الآيدي: $playerId', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(email.isNotEmpty ? email : 'لا يوجد بريد مسجل', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), fontSize: 11)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showRoleChangeBottomSheet(context, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: roleColor.withValues(alpha: 0.15),
                foregroundColor: roleColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeBottomSheet(BuildContext context, Map<String, dynamic> user) {
    final rawRole = user['role'] as String?;
    final targetUserRole = UserRole.fromValue(rawRole);
    final userId = (user['uid'] ?? user['id'] ?? '').toString();
    const adminRole = UserRole.superAdmin;

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: لا يوجد معرّف للمستخدم')));
      return;
    }

    if (!adminRole.canPromoteUser(targetUserRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا تملك صلاحية تعديل رتبة مساوية أو أعلى من رتبتك الحالية (${targetUserRole.displayNameArabic}) 🔒'),
          backgroundColor: Colors.deepOrangeAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ترقية صلاحيات: ${user['displayName'] ?? 'المستخدم'}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(
                'الرتبة الحالية: ${targetUserRole.displayNameArabic} (مستوى ${targetUserRole.rank}). اختر الرتبة الجديدة وفق الصلاحيات المتاحة:',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
              ),
              SizedBox(height: 16),
              ...UserRole.values.map((role) {
                final isEligible = adminRole.canAssignRole(role);
                return _buildRoleOption(
                  ctx,
                  userId,
                  role.toValue(),
                  role.roleTitleArabic,
                  _getRoleIconForDashboard(role),
                  _getRoleColorForDashboard(role),
                  targetUserRole.toValue(),
                  isEligible: isEligible,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  IconData _getRoleIconForDashboard(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.security;
      case UserRole.tournamentAdmin:
        return Icons.emoji_events;
      case UserRole.referee:
        return Icons.sports;
      case UserRole.financeAdmin:
        return Icons.account_balance;
      case UserRole.player:
        return Icons.person;
    }
  }

  Color _getRoleColorForDashboard(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.purpleAccent;
      case UserRole.tournamentAdmin:
        return Colors.orange;
      case UserRole.referee:
        return Colors.blue;
      case UserRole.financeAdmin:
        return Colors.teal;
      case UserRole.player:
        return AppTheme.primaryBlue;
    }
  }

  Widget _buildRoleOption(
    BuildContext context,
    String userId,
    String roleValue,
    String roleName,
    IconData icon,
    Color color,
    String currentRole, {
    bool isEligible = true,
  }) {
    final isSelected = currentRole == roleValue;
    return ListTile(
      enabled: isEligible,
      leading: Icon(icon, color: isEligible ? color : Colors.grey),
      title: Text(
        roleName,
        style: TextStyle(
          color: isEligible ? (isSelected ? color : Theme.of(context).colorScheme.onSurface) : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: !isEligible ? Text('غير متاح (يتطلب رتبة أعلى)', style: TextStyle(color: Colors.redAccent, fontSize: 10)) : null,
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : (!isEligible ? Icon(Icons.lock, size: 16, color: Colors.grey) : null),
      onTap: (!isEligible || isSelected)
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                await FirestoreService().updateUserRole(userId, roleValue);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('تم تغيير الصلاحية إلى $roleName بنجاح ✅', style: TextStyle(color: Colors.black)),
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

