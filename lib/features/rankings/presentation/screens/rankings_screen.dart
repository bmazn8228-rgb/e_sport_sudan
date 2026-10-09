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
  String _selectedState = 'السودان'; // Default is all of Sudan
  final List<String> _games = ['PUBG Mobile', 'EA FC 25', 'Free Fire', 'Valorant'];
  
  final List<String> _sudanStates = [
    'السودان', // General
    'الخرطوم',
    'الجزيرة',
    'البحر الأحمر',
    'كسلا',
    'القضارف',
    'نهر النيل',
    'الشمالية',
    'شمال كردفان',
    'جنوب كردفان',
    'غرب كردفان',
    'شمال دارفور',
    'جنوب دارفور',
    'غرب دارفور',
    'شرق دارفور',
    'وسط دارفور',
    'سنار',
    'النيل الأبيض',
    'النيل الأزرق',
  ];

  final FirestoreService _firestoreService = FirestoreService();

  void _onTabChanged(int index) {
    if (_selectedTabIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedTabIndex = index);
  }

  void _onStateChanged(String? state) {
    if (state == null || _selectedState == state) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedState = state);
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
    if (mmr >= 1000) return Color(0xFFCFD8DC);
    return Color(0xFFBCAAA4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'التصنيف والإحصائيات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                final isSelected = game == _selectedGame;
                return Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => _onGameChanged(game),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryBlue
                            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          game,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
          SizedBox(height: 12),

          // 2. iOS-Style Apple Segmented Control Tab Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(0xFF131822),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
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
          
          if (_selectedTabIndex != 2) ...[
            SizedBox(height: 12),
            // State Selector
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 18, color: AppTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text('المنطقة:', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                    SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedState,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryBlue),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          items: _sudanStates.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(state == 'السودان' ? 'على مستوى السودان' : 'ولاية $state'),
                            );
                          }).toList(),
                          onChanged: _onStateChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          SizedBox(height: 14),

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
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
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
      stream: _selectedTabIndex == 0
          ? _firestoreService.getTeamsStream(game: _selectedGame)
          : _firestoreService.getPlayersStream(game: _selectedGame),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('حدث خطأ في تحميل التصنيفات', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          );
        }

        var list = snapshot.data ?? [];
        
        // Filter by state if not 'السودان'
        if (_selectedState != 'السودان') {
          list = list.where((item) {
            final city = item['city']?.toString() ?? item['state']?.toString() ?? '';
            return city.contains(_selectedState);
          }).toList();
        }
        
        // Sort by Elo
        list.sort((a, b) {
          final eloA = (a['stats']?['elo'] as num?)?.toInt() ?? 1000;
          final eloB = (b['stats']?['elo'] as num?)?.toInt() ?? 1000;
          return eloB.compareTo(eloA);
        });

        // Add Rank dynamically
        for (int i = 0; i < list.length; i++) {
          list[i]['rank'] = i + 1;
        }

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.leaderboard_outlined, size: 54, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                ),
                SizedBox(height: 16),
                Text(
                  _selectedState == 'السودان' ? 'لا يوجد تصنيفات حالياً' : 'لا يوجد تصنيفات في ولاية $_selectedState',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                SizedBox(height: 6),
                Text(
                  'سيتم تحديث قائمة المتصدرين مع انطلاق أولى مباريات الموسم.',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Apple Fitness-Style Podium (Top 3)
              if (list.length >= 3) ...[
                SizedBox(height: 12),
                _buildPodium(list),
                SizedBox(height: 28),
              ],

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTabIndex == 0 ? 'قائمة الفرق المتنافسة' : 'قائمة اللاعبين المصنفين',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedState == 'السودان' ? 'الموسم 1 - $_selectedGame' : '$_selectedState - $_selectedGame',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

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
        Expanded(child: _buildPodiumColumn(rank2, 130, Color(0xFFCFD8DC), 2)),
        SizedBox(width: 8),
        // Rank 1 (Center Champion)
        Expanded(child: _buildPodiumColumn(rank1, 165, Colors.amber, 1, isGold: true)),
        SizedBox(width: 8),
        // Rank 3 (Left side in Arabic RTL)
        Expanded(child: _buildPodiumColumn(rank3, 110, Color(0xFFBCAAA4), 3)),
      ],
    );
  }

  Widget _buildPodiumColumn(Map<String, dynamic> item, double height, Color medalColor, int rank, {bool isGold = false}) {
    final mmr = (item['stats']?['elo'] as num?)?.toInt() ?? 1000;
    final name = (item['name'] ?? item['displayName'])?.toString() ?? '';

    return Column(
      children: [
        // Champion Crown for #1
        if (isGold)
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
          ),
        
        // Avatar with Ring & Rank Badge
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: EdgeInsets.all(3),
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
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: CircleAvatar(
                radius: isGold ? 28 : 22,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Icon(
                  _selectedTabIndex == 0 ? Icons.security_rounded : Icons.person_rounded,
                  color: isGold ? Colors.amber : Theme.of(context).colorScheme.onSurface,
                  size: isGold ? 30 : 22,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(4),
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
                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // Name and MMR
        Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
        SizedBox(height: 2),
        Text(
          '$mmr MMR',
          style: TextStyle(
            color: isGold ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _getTierName(mmr),
          style: TextStyle(color: _getTierColor(mmr), fontSize: 9, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 10),

        // 3D Podium Block
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isGold
                  ? [
                      Colors.amber.withValues(alpha: 0.25),
                      Color(0xFF161D2B),
                    ]
                  : [
                      medalColor.withValues(alpha: 0.15),
                      Color(0xFF121722),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
    final name = (item['name'] ?? item['displayName'])?.toString() ?? '';
    final mmr = (item['stats']?['elo'] as num?)?.toInt() ?? 1000;
    final wins = item['stats']?['wins'] ?? 0;
    final city = item['city']?.toString() ?? 'السودان';

    return GestureDetector(
      onTap: _selectedTabIndex == 0 ? () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => TeamDetailsScreen(team: item),
        ));
      } : null,
      child: Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13),
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedTabIndex == 0 ? Icons.security_rounded : Icons.person_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 2),
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
                      SizedBox(width: 5),
                      Text(
                        '${_getTierName(mmr)} • $city',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11),
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$mmr MMR',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 12),
                ),
              ),
              SizedBox(height: 3),
              Text(
                '$wins فوز',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11),
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
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final stats = snapshot.data;

        if (stats == null || stats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.analytics_outlined, size: 54, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                ),
                SizedBox(height: 16),
                Text(
                  'يتوفر قريباً',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                SizedBox(height: 6),
                Text(
                  'إحصائيات المباريات واللاعبين تحت المعالجة السحابية.',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إحصائيات $_selectedGame السحابية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              SizedBox(height: 16),
              _buildStatCard('إجمالي المباريات الملعوبة', stats['total_matches']?.toString() ?? '0', Icons.sports_esports_rounded, Colors.cyanAccent),
              SizedBox(height: 12),
              _buildStatCard('عدد اللاعبين المسجلين', stats['total_players']?.toString() ?? '0', Icons.people_alt_rounded, AppTheme.primaryBlue),
              SizedBox(height: 12),
              _buildStatCard(
                _selectedGame == 'PUBG Mobile' ? 'السلاح الأكثر استخداماً' : 'العنصر الأكثر طلباً',
                stats['top_weapon']?.toString() ?? 'M416',
                Icons.track_changes_rounded,
                Colors.purpleAccent,
              ),
              SizedBox(height: 12),
              _buildStatCard('أعلى رقم قياسي محقق', stats['highest_kills']?.toString() ?? 'N/A', Icons.emoji_events_rounded, Colors.orangeAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                SizedBox(height: 4),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

