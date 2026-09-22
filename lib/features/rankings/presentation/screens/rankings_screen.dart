import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_details_screen.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  int _selectedTabIndex = 0; // 0: الفرق, 1: اللاعبين, 2: الألعاب/الإحصائيات
  String _selectedGame = 'PUBG Mobile';
  final List<String> _games = ['PUBG Mobile', 'EA FC 25', 'Free Fire', 'Valorant'];

  final FirestoreService _firestoreService = FirestoreService();

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedTabIndex = index);
  }

  void _onGameChanged(String game) {
    if (_selectedGame == game) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedGame = game);
  }

  String _getTierName(int mmr) {
    if (mmr >= 2500) return 'نخبة السودان';
    if (mmr >= 2000) return 'ماسي';
    if (mmr >= 1500) return 'ذهبي';
    if (mmr >= 1000) return 'فضي';
    return 'برونزي';
  }

  Color _getTierColor(int mmr) {
    if (mmr >= 2500) return Colors.redAccent;
    if (mmr >= 2000) return Colors.blueAccent;
    if (mmr >= 1500) return Colors.amber;
    if (mmr >= 1000) return const Color(0xFFCFD8DC);
    return const Color(0xFFBCAAA4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'التصنيف والإحصائيات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'مزامنة سحابية ☁️',
                style: TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. iOS-Style Game Selector Capsules
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                final isSelected = game == _selectedGame;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => _onGameChanged(game),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : AppTheme.cardDark.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          game,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 2. iOS-Style Apple Segmented Control Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF131822),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  _buildSegmentedTab('تصنيف الفرق', 0),
                  _buildSegmentedTab('تصنيف اللاعبين', 1),
                  _buildSegmentedTab('إحصائيات اللعبة', 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Main Dynamic Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cardDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryBlue : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedTabIndex == 2) {
      return _buildStatsView();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getRankingsStream(
        game: _selectedGame,
        type: _selectedTabIndex == 0 ? 'teams' : 'players',
        season: 'Season 1',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('حدث خطأ في تحميل التصنيفات', style: TextStyle(color: Colors.white54)),
          );
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.leaderboard_outlined, size: 54, color: Colors.white38),
                ),
                const SizedBox(height: 16),
                const Text(
                  'يتوفر قريباً',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                const Text(
                  'سيتم تحديث قائمة المتصدرين مع انطلاق أولى مباريات الموسم.',
                  style: TextStyle(fontSize: 13, color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Apple Fitness-Style Podium (Top 3)
              if (list.length >= 3) ...[
                const SizedBox(height: 12),
                _buildPodium(list),
                const SizedBox(height: 28),
              ],

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTabIndex == 0 ? 'قائمة الفرق المتنافسة' : 'قائمة اللاعبين المصنفين',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'الموسم 1 - $_selectedGame',
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Remaining Leaderboard Items
              ...list.skip(list.length >= 3 ? 3 : 0).map((item) => _buildListItem(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> list) {
    final rank1 = list[0];
    final rank2 = list[1];
    final rank3 = list[2];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rank 2 (Right side in Arabic RTL)
        Expanded(child: _buildPodiumColumn(rank2, 130, const Color(0xFFCFD8DC), 2)),
        const SizedBox(width: 8),
        // Rank 1 (Center Champion)
        Expanded(child: _buildPodiumColumn(rank1, 165, Colors.amber, 1, isGold: true)),
        const SizedBox(width: 8),
        // Rank 3 (Left side in Arabic RTL)
        Expanded(child: _buildPodiumColumn(rank3, 110, const Color(0xFFBCAAA4), 3)),
      ],
    );
  }

  Widget _buildPodiumColumn(Map<String, dynamic> item, double height, Color medalColor, int rank, {bool isGold = false}) {
    final mmr = (item['mmr'] is int) ? item['mmr'] as int : int.tryParse(item['mmr']?.toString() ?? '1000') ?? 1000;
    final name = item['name']?.toString() ?? '';

    return Column(
      children: [
        // Champion Crown for #1
        if (isGold)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
          ),
        
        // Avatar with Ring & Rank Badge
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isGold
                      ? [Colors.amber, Colors.orangeAccent]
                      : [medalColor.withValues(alpha: 0.8), medalColor.withValues(alpha: 0.3)],
                ),
                boxShadow: isGold
                    ? [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: isGold ? 28 : 22,
                backgroundColor: AppTheme.cardDark,
                child: Icon(
                  _selectedTabIndex == 0 ? Icons.security_rounded : Icons.person_rounded,
                  color: isGold ? Colors.amber : Colors.white,
                  size: isGold ? 30 : 22,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: medalColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '$rank',
                style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Name and MMR
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          '$mmr MMR',
          style: TextStyle(
            color: isGold ? AppTheme.primaryBlue : Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _getTierName(mmr),
          style: TextStyle(color: _getTierColor(mmr), fontSize: 9, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),

        // 3D Podium Block
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isGold
                  ? [
                      Colors.amber.withValues(alpha: 0.25),
                      const Color(0xFF161D2B),
                    ]
                  : [
                      medalColor.withValues(alpha: 0.15),
                      const Color(0xFF121722),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: isGold
                  ? Colors.amber.withValues(alpha: 0.4)
                  : medalColor.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: medalColor.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    final rank = item['rank'] ?? '-';
    final name = item['name']?.toString() ?? '';
    final mmr = (item['mmr'] is int) ? item['mmr'] as int : int.tryParse(item['mmr']?.toString() ?? '1000') ?? 1000;
    final wins = item['wins'] ?? 0;
    final city = item['city']?.toString() ?? 'السودان';

    return GestureDetector(
      onTap: _selectedTabIndex == 0 ? () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => TeamDetailsScreen(team: item),
        ));
      } : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white38, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedTabIndex == 0 ? Icons.security_rounded : Icons.person_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getTierColor(mmr),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_getTierName(mmr)} • $city',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$mmr MMR',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 12),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$wins فوز',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  Widget _buildStatsView() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _firestoreService.getGameStats(_selectedGame),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final stats = snapshot.data;

        if (stats == null || stats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_outlined, size: 54, color: Colors.white38),
                ),
                const SizedBox(height: 16),
                const Text(
                  'يتوفر قريباً',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                const Text(
                  'إحصائيات المباريات واللاعبين تحت المعالجة السحابية.',
                  style: TextStyle(fontSize: 13, color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إحصائيات $_selectedGame السحابية',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 16),
              _buildStatCard('إجمالي المباريات الملعوبة', stats['total_matches']?.toString() ?? '0', Icons.sports_esports_rounded, Colors.cyanAccent),
              const SizedBox(height: 12),
              _buildStatCard('عدد اللاعبين المسجلين', stats['total_players']?.toString() ?? '0', Icons.people_alt_rounded, AppTheme.primaryBlue),
              const SizedBox(height: 12),
              _buildStatCard(
                _selectedGame == 'PUBG Mobile' ? 'السلاح الأكثر استخداماً' : 'العنصر الأكثر طلباً',
                stats['top_weapon']?.toString() ?? 'M416',
                Icons.track_changes_rounded,
                Colors.purpleAccent,
              ),
              const SizedBox(height: 12),
              _buildStatCard('أعلى رقم قياسي محقق', stats['highest_kills']?.toString() ?? 'N/A', Icons.emoji_events_rounded, Colors.orangeAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
