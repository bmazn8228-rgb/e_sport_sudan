import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({Key? key}) : super(key: key);

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  int _selectedTabIndex = 0; // 0: الفرق, 1: اللاعبين, 2: الألعاب/الإحصائيات
  String _selectedGame = 'PUBG Mobile';
  final List<String> _games = ['PUBG Mobile', 'EA FC 25', 'Free Fire', 'Valorant'];

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
  }

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
  }

  void _onGameChanged(String game) {
    if (_selectedGame == game) return;
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
    if (mmr >= 1000) return Colors.grey[300]!;
    return Colors.brown[300]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text('التصنيف والإحصائيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('مزامنة سحابية ☁️', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Game Selector (Horizontal Scroll)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                final isSelected = game == _selectedGame;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(game, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.cardDark,
                    onSelected: (_) => _onGameChanged(game),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // 2. Tabs Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('تصنيف الفرق', 0),
                  _buildTab('تصنيف اللاعبين', 1),
                  _buildTab('إحصائيات اللعبة', 2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
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
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ في تحميل التصنيفات', style: TextStyle(color: Colors.white54)));
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return const Center(child: Text('لا توجد بيانات متاحة حالياً', style: TextStyle(color: Colors.white54)));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top 3 Podium (Rank 2 | Rank 1 | Rank 3 in RTL)
              if (list.length >= 3) _buildPodium(list),
              
              if (list.length >= 3) const SizedBox(height: 28),

              // Remaining Leaderboard List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_selectedTabIndex == 0 ? 'قائمة الفرق' : 'قائمة اللاعبين', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('الموسم 1 - $_selectedGame', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 12),

              ...list.skip(list.length >= 3 ? 3 : 0).map((item) => _buildListItem(item)),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatsView() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _firestoreService.getGameStats(_selectedGame),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
        }

        final stats = snapshot.data;

        if (stats == null || stats.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد إحصائيات متوفرة لهذه اللعبة حتى الآن',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إحصائيات $_selectedGame السحابية', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              const SizedBox(height: 20),
              _buildStatCard('إجمالي المباريات الملعوبة', stats['total_matches']?.toString() ?? '0', Icons.sports_esports),
              const SizedBox(height: 12),
              _buildStatCard('عدد اللاعبين المسجلين', stats['total_players']?.toString() ?? '0', Icons.people),
              const SizedBox(height: 12),
              _buildStatCard(_selectedGame == 'PUBG Mobile' ? 'السلاح الأكثر استخداماً' : 'ملاحظات', stats['top_weapon']?.toString() ?? 'N/A', Icons.track_changes),
              const SizedBox(height: 12),
              _buildStatCard('أعلى رقم قياسي', stats['highest_kills']?.toString() ?? 'N/A', Icons.emoji_events, color: Colors.orange),
            ],
          ),
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {Color color = AppTheme.primaryGreen}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
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

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> list) {
    final rank1 = list[0];
    final rank2 = list[1];
    final rank3 = list[2];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildPodiumItem(rank2, 130, Colors.grey[400]!, 2)),
        const SizedBox(width: 8),
        Expanded(child: _buildPodiumItem(rank1, 160, Colors.amber, 1, isGold: true)),
        const SizedBox(width: 8),
        Expanded(child: _buildPodiumItem(rank3, 110, Colors.brown[300]!, 3)),
      ],
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> item, double height, Color medalColor, int rank, {bool isGold = false}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: isGold ? 28 : 22,
              backgroundColor: AppTheme.cardDark,
              child: Icon(_selectedTabIndex == 0 ? Icons.security : Icons.person, color: isGold ? AppTheme.primaryGreen : Colors.white, size: isGold ? 30 : 24),
            ),
            CircleAvatar(
              radius: 9,
              backgroundColor: medalColor,
              child: Text('$rank', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        Text('${item['mmr']} MMR', style: TextStyle(color: isGold ? AppTheme.primaryGreen : Colors.white54, fontSize: 10)),
        Text(_getTierName(item['mmr'] ?? 1000), style: TextStyle(color: _getTierColor(item['mmr'] ?? 1000), fontSize: 9)),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: isGold ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)) : null,
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: medalColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                '#${item['rank']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white12,
                child: Icon(_selectedTabIndex == 0 ? Icons.security : Icons.person, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getTierColor(item['mmr'] ?? 1000),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${_getTierName(item['mmr'] ?? 1000)} | ${item['city']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['mmr']} MMR',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 13),
              ),
              Text(
                '${item['wins']} فوز',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
}
