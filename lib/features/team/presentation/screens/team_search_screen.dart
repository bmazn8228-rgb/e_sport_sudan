import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:e_sport_sudan/features/shared/presentation/screens/qr_scanner_screen.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_details_screen.dart';

class TeamSearchScreen extends StatefulWidget {
  final String? initialQuery;
  const TeamSearchScreen({super.key, this.initialQuery});

  @override
  State<TeamSearchScreen> createState() => _TeamSearchScreenState();
}

class _TeamSearchScreenState extends State<TeamSearchScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'id', 'name'
  final Set<String> _loadingTeamIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!.trim();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Normalizes Arabic text and converts Eastern Arabic numerals to standard digits
  String _normalize(String input) {
    var text = input.trim().toLowerCase();
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(arabicNumerals[i], i.toString());
    }
    return text;
  }

  /// Checks if a team matches current query and filter type (supports ID & Name)
  bool _matchesQuery(Map<String, dynamic> team) {
    if (_searchQuery.isEmpty) return true;

    final queryNorm = _normalize(_searchQuery);
    final cleanIdQuery = queryNorm.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    final teamName = _normalize(team['name']?.toString() ?? '');
    final teamId = (team['id']?.toString() ?? '').toLowerCase();
    final cleanTeamId = teamId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final customId = (team['teamId']?.toString() ?? '').toLowerCase();
    final code = (team['code']?.toString() ?? '').toLowerCase();
    final game = _normalize(team['game']?.toString() ?? '');

    final bool matchId = (cleanIdQuery.isNotEmpty && cleanTeamId.contains(cleanIdQuery)) ||
        teamId.contains(queryNorm) ||
        customId.contains(queryNorm) ||
        code.contains(queryNorm);

    final bool matchName = teamName.contains(queryNorm);
    final bool matchGame = game.contains(queryNorm);

    if (_filterType == 'id') {
      return matchId;
    } else if (_filterType == 'name') {
      return matchName;
    } else {
      return matchName || matchId || matchGame;
    }
  }

  Future<void> _joinTeam(String teamId, String teamName, Map<String, dynamic> teamData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      NotificationService.showCustomToast(
        context,
        title: 'تنبيه',
        message: 'يرجى تسجيل الدخول أولاً للانضمام للفريق.',
        type: ToastType.urgent,
      );
      return;
    }

    setState(() => _loadingTeamIds.add(teamId));

    try {
      String displayName = user.displayName ?? 'لاعب مجهول';
      String ign = '';
      try {
        final userDoc = await _firestoreService.getUser(user.uid);
        if (userDoc != null) {
          if (userDoc.displayName.isNotEmpty) displayName = userDoc.displayName;
          if (userDoc.ign != null && userDoc.ign!.isNotEmpty) ign = userDoc.ign!;
        }
      } catch (_) {}

      final playerRosterData = {
        'uid': user.uid,
        'displayName': displayName,
        'name': displayName,
        'email': user.email ?? '',
        'ign': ign,
        'role': 'عضو',
        'joinedAt': DateTime.now().toIso8601String(),
      };

      await _firestoreService.joinTeam(teamId, user.uid, playerRosterData);

      if (mounted) {
        NotificationService.showCustomToast(
          context,
          title: 'تم الانضمام 🏆',
          message: 'تم الانضمام إلى فريق "$teamName" بنجاح!',
          type: ToastType.success,
        );
        Navigator.pop(context, true); // Refresh parent screen
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showCustomToast(
          context,
          title: 'خطأ',
          message: 'فشل الانضمام للفريق: $e',
          type: ToastType.urgent,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTeamIds.remove(teamId));
      }
    }
  }

  Future<void> _requestToJoin(String teamId, String teamName, Map<String, dynamic> teamData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      NotificationService.showCustomToast(
        context,
        title: 'تنبيه',
        message: 'يرجى تسجيل الدخول أولاً.',
        type: ToastType.urgent,
      );
      return;
    }

    setState(() => _loadingTeamIds.add(teamId));

    try {
      String displayName = user.displayName ?? 'لاعب مجهول';
      String ign = '';
      try {
        final userDoc = await _firestoreService.getUser(user.uid);
        if (userDoc != null) {
          if (userDoc.displayName.isNotEmpty) displayName = userDoc.displayName;
          if (userDoc.ign != null && userDoc.ign!.isNotEmpty) ign = userDoc.ign!;
        }
      } catch (_) {}

      final playerRosterData = {
        'uid': user.uid,
        'displayName': displayName,
        'name': displayName,
        'email': user.email ?? '',
        'ign': ign,
        'role': 'عضو',
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
      };

      await _firestoreService.requestToJoinTeam(teamId, playerRosterData);

      if (mounted) {
        NotificationService.showCustomToast(
          context,
          title: 'تم إرسال الطلب ⏳',
          message: 'تم إرسال طلب الانضمام لقائد فريق "$teamName" بنجاح!',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showCustomToast(
          context,
          title: 'خطأ',
          message: 'فشل إرسال الطلب: $e',
          type: ToastType.urgent,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTeamIds.remove(teamId));
      }
    }
  }

  void _openTeamDetails(Map<String, dynamic> team) async {
    final joined = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeamDetailsScreen(team: team)),
    );
    if (joined == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _copyTeamId(String id) {
    if (id.isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: id));
    NotificationService.showCustomToast(
      context,
      title: 'تم النسخ',
      message: 'تم نسخ معرف الفريق ($id) إلى الحافظة',
      type: ToastType.social,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث عن فريق', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          _buildSearchHeader(isDark),

          // Teams Stream List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getAllTeamsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'حدث خطأ أثناء تحميل الفرق: ${snapshot.error}',
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allTeams = snapshot.data ?? [];
                final filteredTeams = allTeams.where(_matchesQuery).toList();

                if (filteredTeams.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filteredTeams.length,
                  itemBuilder: (context, index) {
                    final team = filteredTeams[index];
                    return _buildTeamCard(team, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _searchQuery.isNotEmpty
                    ? AppTheme.primaryBlue
                    : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300),
                width: _searchQuery.isNotEmpty ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث باسم الفريق أو معرف الـ ID...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 20),
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        tooltip: 'مسح البحث',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 24,
                      width: 1,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryBlue),
                      tooltip: 'مسح معرف الفريق عبر QR',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(title: 'مسح معرف الفريق'),
                          ),
                        );
                        if (result != null && result is String && mounted) {
                          final cleanResult = result.trim();
                          _searchController.text = cleanResult;
                          setState(() => _searchQuery = cleanResult);
                        }
                      },
                    ),
                  ],
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip(label: 'الكل', value: 'all', icon: Icons.grid_view_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'بالمعرف (ID)', value: 'id', icon: Icons.tag_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(label: 'بالاسم', value: 'name', icon: Icons.badge_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required String value, required IconData icon}) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : Theme.of(context).dividerColor.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _searchQuery.isNotEmpty
                  ? 'لم يتم العثور على أي فريق يطابق "$_searchQuery"'
                  : 'لا توجد فرق متاحة حالياً',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'تأكد من كتابة اسم الفريق أو رقم المعرف (ID) بشكل صحيح، أو جرب مسح رمز QR.'
                  : 'يمكنك إنشاء فريق جديد من شاشة إدارة الفرق أو البحث لاحقاً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('عرض جميع الفرق'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team, bool isDark) {
    final teamId = (team['id'] ?? '').toString();
    final teamName = (team['name'] ?? 'بدون اسم').toString();
    final game = (team['game'] ?? 'غير محدد').toString();
    final roster = (team['roster'] as List?) ?? [];
    final memberCount = roster.length;
    final points = team['points'] ?? 0;
    final joinType = (team['joinType'] ?? 'public').toString();
    final isApproval = joinType == 'approval';

    // Status checks for current user
    final isLeader = team['leaderId'] == _currentUid;
    final isMember = isLeader || roster.any((m) => (m is Map && m['uid'] == _currentUid));
    final pendingRequests = (team['pendingRequests'] as List?) ?? [];
    final bool hasRequested = pendingRequests.any((req) => (req is Map && req['uid'] == _currentUid));
    final bool isLoading = _loadingTeamIds.contains(teamId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openTeamDetails(team),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Logo + Team info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Logo
                    _buildTeamLogo(team),

                    const SizedBox(width: 14),

                    // Team Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Team Name & Join Type Badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  teamName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildJoinTypeBadge(isApproval),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Team ID (Click to copy)
                          if (teamId.isNotEmpty)
                            InkWell(
                              onTap: () => _copyTeamId(teamId),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.tag_rounded,
                                      size: 13,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ID: $teamId',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlue,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 12,
                                      color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Stats chips: Game & Members & Points
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildMiniBadge(
                                icon: Icons.sports_esports_rounded,
                                text: game,
                                color: Colors.purpleAccent,
                              ),
                              _buildMiniBadge(
                                icon: Icons.people_alt_rounded,
                                text: '$memberCount لاعبين',
                                color: Colors.blueAccent,
                              ),
                              if (points > 0)
                                _buildMiniBadge(
                                  icon: Icons.emoji_events_rounded,
                                  text: '$points نقطة',
                                  color: Colors.amber,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 12),

                // Actions Row: (1) Details Button & (2) Join/Status Button
                Row(
                  children: [
                    // Option 1: View Team Details
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openTeamDetails(team),
                        icon: const Icon(Icons.info_outline_rounded, size: 17),
                        label: const Text(
                          'عرض التفاصيل',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: BorderSide(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Option 2: Join or Status Button
                    Expanded(
                      child: _buildActionJoinButton(
                        teamId: teamId,
                        teamName: teamName,
                        teamData: team,
                        isMember: isMember,
                        hasRequested: hasRequested,
                        isApproval: isApproval,
                        isLoading: isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamLogo(Map<String, dynamic> team) {
    final logoUrl = (team['logoUrl'] ?? '').toString().trim();
    final teamName = (team['name'] ?? 'ف').toString().trim();
    final initial = teamName.isNotEmpty ? teamName.substring(0, 1).toUpperCase() : 'T';

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.25),
            AppTheme.primaryBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: logoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                width: 58,
                height: 58,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildLogoFallback(initial),
              )
            : _buildLogoFallback(initial),
      ),
    );
  }

  Widget _buildLogoFallback(String initial) {
    return Container(
      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildJoinTypeBadge(bool isApproval) {
    final color = isApproval ? Colors.orangeAccent : Colors.tealAccent.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isApproval ? Icons.lock_outline_rounded : Icons.bolt_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            isApproval ? 'بالموافقة' : 'عام',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionJoinButton({
    required String teamId,
    required String teamName,
    required Map<String, dynamic> teamData,
    required bool isMember,
    required bool hasRequested,
    required bool isApproval,
    required bool isLoading,
  }) {
    // 1. Loading state
    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    // 2. User is already in this team
    if (isMember) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
        label: const Text(
          'أنت عضو',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // 3. User already sent a join request that is pending
    if (hasRequested) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.orangeAccent),
        label: const Text(
          'قيد الانتظار',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5)),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // 4. Approval-based team: Request to join
    if (isApproval) {
      return ElevatedButton.icon(
        onPressed: () => _requestToJoin(teamId, teamName, teamData),
        icon: const Icon(Icons.send_rounded, size: 16, color: Colors.black),
        label: const Text(
          'طلب انضمام',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          elevation: 2,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // 5. Public team: Instant Join
    return ElevatedButton.icon(
      onPressed: () => _joinTeam(teamId, teamName, teamData),
      icon: const Icon(Icons.group_add_rounded, size: 16, color: Colors.white),
      label: const Text(
        'انضمام للفريق',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        elevation: 2,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
