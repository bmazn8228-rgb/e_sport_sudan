import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class RegisteredPlayersScreen extends StatefulWidget {
  const RegisteredPlayersScreen({super.key});

  @override
  State<RegisteredPlayersScreen> createState() => _RegisteredPlayersScreenState();
}

class _RegisteredPlayersScreenState extends State<RegisteredPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'player', 'referee', 'finance_admin', 'tournament_admin', 'super_admin'
  UserRole _currentAdminRole = UserRole.superAdmin;
  bool _isLoadingAdminRole = true;

  @override
  void initState() {
    super.initState();
    _resolveCurrentAdminRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolveCurrentAdminRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoadingAdminRole = false);
      return;
    }

    final emailRole = AuthService().getRoleForEmail(currentUser.email ?? '');
    try {
      final userDoc = await FirestoreService().getUser(currentUser.uid, forceRefresh: true);
      final firestoreRole = userDoc?.role ?? UserRole.player;

      // Take the higher rank between email and Firestore document
      final resolvedRole = emailRole.rank >= firestoreRole.rank ? emailRole : firestoreRole;

      if (mounted) {
        setState(() {
          _currentAdminRole = resolvedRole;
          _isLoadingAdminRole = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentAdminRole = emailRole != UserRole.player ? emailRole : UserRole.superAdmin;
          _isLoadingAdminRole = false;
        });
      }
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.purpleAccent;
      case UserRole.tournamentAdmin:
        return Colors.orangeAccent;
      case UserRole.financeAdmin:
        return Colors.tealAccent;
      case UserRole.referee:
        return Colors.blueAccent;
      case UserRole.player:
        return AppTheme.primaryBlue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.shield_rounded;
      case UserRole.tournamentAdmin:
        return Icons.emoji_events_rounded;
      case UserRole.financeAdmin:
        return Icons.account_balance_wallet_rounded;
      case UserRole.referee:
        return Icons.sports_rounded;
      case UserRole.player:
        return Icons.sports_esports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اللاعبين والمستخدمين المسجلين',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'رتبتك: ${_currentAdminRole.displayNameArabic} (مستوى ${_currentAdminRole.rank})',
              style: TextStyle(
                fontSize: 11,
                color: _getRoleColor(_currentAdminRole).withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              setState(() {});
              _resolveCurrentAdminRole();
            },
          ),
        ],
      ),
      body: _isLoadingAdminRole
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getAllUsersStream(limit: 500),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text('فشل تحميل قائمة المستخدمين: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  );
                }

                final allUsers = snapshot.data ?? [];

                // Metrics calculation
                final totalCount = allUsers.length;
                final playersCount = allUsers.where((u) => (u['role'] ?? 'player') == 'player').length;
                final refereesCount = allUsers.where((u) => u['role'] == 'referee').length;
                final organizersCount = allUsers.where((u) => u['role'] == 'tournament_admin').length;
                final financeCount = allUsers.where((u) => u['role'] == 'finance_admin').length;
                final superAdminsCount = allUsers.where((u) => u['role'] == 'super_admin').length;

                // Filtering by search and role
                var filteredUsers = allUsers.where((user) {
                  final role = (user['role'] ?? 'player').toString();
                  if (_selectedRoleFilter != 'all' && role != _selectedRoleFilter) {
                    return false;
                  }

                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final name = (user['displayName'] ?? '').toString().toLowerCase();
                    final ign = (user['ign'] ?? '').toString().toLowerCase();
                    final email = (user['email'] ?? '').toString().toLowerCase();
                    final phone = (user['phone'] ?? '').toString().toLowerCase();
                    final playerId = (user['playerId'] ?? '').toString().toLowerCase();
                    return name.contains(q) || ign.contains(q) || email.contains(q) || phone.contains(q) || playerId.contains(q);
                  }

                  return true;
                }).toList();

                return Column(
                  children: [
                    // Top Telemetry & Statistics Row
                    _buildTopMetricsBanner(
                      totalCount: totalCount,
                      playersCount: playersCount,
                      refereesCount: refereesCount,
                      organizersCount: organizersCount,
                      financeCount: financeCount,
                      superAdminsCount: superAdminsCount,
                    ),

                    // Search & Filters Box
                    _buildSearchAndFilterControls(
                      totalCount: totalCount,
                      playersCount: playersCount,
                      refereesCount: refereesCount,
                      organizersCount: organizersCount,
                      financeCount: financeCount,
                      superAdminsCount: superAdminsCount,
                    ),

                    // User List
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return _buildUserCard(context, user);
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTopMetricsBanner({
    required int totalCount,
    required int playersCount,
    required int refereesCount,
    required int organizersCount,
    required int financeCount,
    required int superAdminsCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat('إجمالي المسجلين', '$totalCount', AppTheme.primaryBlue, Icons.people_alt_rounded),
          _buildDivider(),
          _buildMiniStat('اللاعبين', '$playersCount', Colors.cyanAccent, Icons.sports_esports_rounded),
          _buildDivider(),
          _buildMiniStat('الحكام', '$refereesCount', Colors.blueAccent, Icons.sports_rounded),
          _buildDivider(),
          _buildMiniStat('المنظمين', '$organizersCount', Colors.orangeAccent, Icons.emoji_events_rounded),
          _buildDivider(),
          _buildMiniStat('المشرفين', '${financeCount + superAdminsCount}', Colors.purpleAccent, Icons.shield_rounded),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28,
      width: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }

  Widget _buildMiniStat(String title, String val, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
      ],
    );
  }

  Widget _buildSearchAndFilterControls({
    required int totalCount,
    required int playersCount,
    required int refereesCount,
    required int organizersCount,
    required int financeCount,
    required int superAdminsCount,
  }) {
    return Column(
      children: [
        // Search Input Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم، اللقب (IGN)، الآيدي، البريد أو الهاتف...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.50),
                fontSize: 12,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryBlue, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
              ),
            ),
          ),
        ),

        // Role Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip('all', 'الكل ($totalCount)', AppTheme.primaryBlue),
              const SizedBox(width: 8),
              _buildFilterChip('player', 'اللاعبين ($playersCount)', Colors.cyanAccent),
              const SizedBox(width: 8),
              _buildFilterChip('referee', 'الحكام ($refereesCount)', Colors.blueAccent),
              const SizedBox(width: 8),
              _buildFilterChip('tournament_admin', 'المنظمين ($organizersCount)', Colors.orangeAccent),
              const SizedBox(width: 8),
              _buildFilterChip('finance_admin', 'المالية ($financeCount)', Colors.tealAccent),
              const SizedBox(width: 8),
              _buildFilterChip('super_admin', 'الإدارة العليا ($superAdminsCount)', Colors.purpleAccent),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, Color color) {
    final isSelected = _selectedRoleFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final rawRole = user['role'] as String?;
    final userRole = UserRole.fromValue(rawRole);
    final roleColor = _getRoleColor(userRole);
    final roleIcon = _getRoleIcon(userRole);

    final displayName = (user['displayName'] ?? '').toString().trim();
    final name = displayName.isNotEmpty ? displayName : 'مستخدم بدون اسم';
    final ign = (user['ign'] ?? '').toString().trim();
    final email = (user['email'] ?? '').toString().trim();
    final phone = (user['phone'] ?? '').toString().trim();
    final playerId = (user['playerId'] ?? user['id'] ?? '').toString();
    final userId = (user['uid'] ?? user['id'] ?? '').toString();
    final photoUrl = user['photoUrl'] as String?;

    // Check rank permissions strictly:
    // "الادمن يستطيع ترقيه اي شخص الى ادمن من الرتب الاقل من رتبته فقط"
    final bool canPromoteThisUser = _currentAdminRole.canPromoteUser(userRole);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canPromoteThisUser
              ? roleColor.withValues(alpha: 0.20)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Role Indicator Badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: roleColor, width: 1.5),
                        ),
                        child: Icon(roleIcon, size: 10, color: roleColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(roleIcon, size: 11, color: roleColor),
                                const SizedBox(width: 4),
                                Text(
                                  userRole.displayNameArabic,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: roleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // IGN and Player ID Row
                      Row(
                        children: [
                          if (ign.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'IGN: $ign',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (playerId.isNotEmpty) ...[
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: playerId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم نسخ الآيدي: $playerId ✅'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'ID: #$playerId',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Email / Phone Info
                      if (email.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.phone_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Row: Promotion or Locked Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rank Level info
                Text(
                  'مستوى الرتبة: ${userRole.rank}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),

                // Promote / Change Role Button
                if (canPromoteThisUser)
                  ElevatedButton.icon(
                    onPressed: () => _showPromotionSheet(context, user, userId, name, userRole),
                    icon: const Icon(Icons.shield_outlined, size: 14),
                    label: const Text('ترقية الصلاحيات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      foregroundColor: roleColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: roleColor.withValues(alpha: 0.4)),
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ترقية وتعديل الرتب مخصصة لمدير النظام (Super Admin) فقط 🔒'),
                          backgroundColor: Colors.deepOrangeAccent,
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_rounded, size: 13, color: Colors.grey),
                    label: const Text('غير مصرح بالترقية 🔒', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionSheet(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
    String userName,
    UserRole currentUserRole,
  ) {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ: معرّف المستخدم غير متوفر')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with user name and current role
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRoleColor(currentUserRole).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.security_update_good_rounded, color: _getRoleColor(currentUserRole), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ترقية وتعديل رتبة: $userName',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'الرتبة الحالية: ${currentUserRole.roleTitleArabic}',
                              style: TextStyle(
                                fontSize: 11,
                                color: _getRoleColor(currentUserRole),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Admin authority note
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'وفقاً للسياسة الأمنية للمنظومة، يحق للسوبر أدمن فقط ترقية وتعديل رتب المستخدمين.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'اختر الرتبة الجديدة المطلوبة:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // List of all roles with permission checks
                  ...UserRole.values.map((candidateRole) {
                    final isCurrentRole = candidateRole == currentUserRole;
                    final bool isEligible = _currentAdminRole.canAssignRole(candidateRole);
                    final color = _getRoleColor(candidateRole);
                    final icon = _getRoleIcon(candidateRole);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrentRole
                            ? color.withValues(alpha: 0.12)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentRole
                              ? color
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          width: isCurrentRole ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        enabled: isEligible && !isCurrentRole,
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isEligible ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                          child: Icon(icon, size: 16, color: isEligible ? color : Colors.grey),
                        ),
                        title: Row(
                          children: [
                            Text(
                              candidateRole.roleTitleArabic,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrentRole ? FontWeight.bold : FontWeight.w600,
                                color: isEligible
                                    ? (isCurrentRole ? color : Theme.of(context).colorScheme.onSurface)
                                    : Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isEligible ? color : Colors.grey).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'مستوى ${candidateRole.rank}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isEligible ? color : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          isCurrentRole
                              ? 'الرتبة الحالية للمستخدم'
                              : (!isEligible
                                  ? 'غير متاح (يتطلب رتبة أعلى من رتبتك)'
                                  : 'ترقية وتحديث الصلاحيات فوراً في Firebase'),
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrentRole
                                ? color
                                : (!isEligible ? Colors.redAccent.withValues(alpha: 0.7) : Colors.grey),
                          ),
                        ),
                        trailing: isCurrentRole
                            ? Icon(Icons.check_circle_rounded, color: color, size: 20)
                            : (!isEligible
                                ? const Icon(Icons.lock_rounded, color: Colors.grey, size: 16)
                                : const Icon(Icons.arrow_forward_ios_rounded, size: 14)),
                        onTap: (!isEligible || isCurrentRole)
                            ? null
                            : () => _confirmAndPromoteUser(
                                  context,
                                  bottomSheetContext,
                                  userId,
                                  userName,
                                  candidateRole,
                                ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmAndPromoteUser(
    BuildContext parentContext,
    BuildContext bottomSheetContext,
    String userId,
    String userName,
    UserRole newRole,
  ) {
    showDialog(
      context: bottomSheetContext,
      builder: (dialogCtx) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(parentContext).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(_getRoleIcon(newRole), color: _getRoleColor(newRole)),
                  const SizedBox(width: 8),
                  const Text('تأكيد ترقية المستخدم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('هل أنت متأكد من تغيير رتبة المستخدم: "$userName"؟'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getRoleColor(newRole).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getRoleColor(newRole).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('الرتبة الجديدة: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          newRole.roleTitleArabic,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(newRole),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم حفظ التغيير فوراً في Firebase Cloud وإرسال إشعار فوري بحسابه.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(parentContext).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx),
                  child: Text('إلغاء', style: TextStyle(color: Theme.of(parentContext).colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRoleColor(newRole),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() => isProcessing = true);
                          try {
                            await FirestoreService().updateUserRole(userId, newRole.toValue());
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            if (bottomSheetContext.mounted) Navigator.pop(bottomSheetContext);

                            if (parentContext.mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text('تمت ترقية $userName إلى ${newRole.roleTitleArabic} بنجاح ✅', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppTheme.primaryBlue,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isProcessing = false);
                            if (parentContext.mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(content: Text('فشل تنفيذ الترقية: $e ❌'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('تأكيد الترقية ✅', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 54, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text(
              _searchQuery.isNotEmpty ? 'لم يتم العثور على لاعبين مطابقين للبحث' : 'لا يوجد لاعبين مسجلين في هذا القسم',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty ? 'جرّب البحث باسم آخر أو آيدي مختلف' : 'سيظهر اللاعبون المسجلون هنا فور تسجيلهم في المنظومة',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
