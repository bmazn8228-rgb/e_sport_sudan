import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'bracket_screen.dart';
import 'tournament_registration_screen.dart';
import 'tournament_details_screen.dart';

class TournamentsScreen extends StatefulWidget {
  final bool isGuest;
  const TournamentsScreen({super.key, this.isGuest = false});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _selectedGame = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'استكشف البطولات السودانية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // iOS-Style Squircle Search Field
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ابحث عن بطولة أو تصفيات ولائية...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // iOS-Style Capsule Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ['الكل', 'PUBG Mobile', 'EA FC 25', 'Free Fire', 'Valorant'].map((game) {
                      final isSelected = _selectedGame == game;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedGame = game);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.cardDark.withValues(alpha: 0.7),
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
                            child: Text(
                              game,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getTournamentsStream(
                game: _selectedGame == 'الكل' ? null : _selectedGame,
              ),
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
                        const Text('حدث خطأ في تحميل البطولات.', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {}); // Trigger a rebuild to retry the stream
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                var tournaments = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  tournaments = tournaments.where((t) {
                    final title = (t['title'] ?? '').toString().toLowerCase();
                    final game = (t['game'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || game.contains(_searchQuery);
                  }).toList();
                }

                if (tournaments.isEmpty) {
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
                          child: const Icon(Icons.emoji_events_outlined, size: 54, color: Colors.white38),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد بطولات حالياً',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'سيتم عرض البطولات هنا بمجرد أن يعلن عنها المشرفون.',
                          style: TextStyle(fontSize: 13, color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 120),
                  itemCount: tournaments.length,
                  itemBuilder: (context, index) {
                    final t = tournaments[index];
                    return _buildTournamentCard(context, t);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Map<String, dynamic> t) {
    String statusText = 'غير محدد';
    Color statusColor = Colors.grey;
    bool isLive = false;
    
    final status = t['status']?.toString().toLowerCase() ?? '';
    
    if (status == 'upcoming' || status == 'open') {
      statusText = 'التسجيل مفتوح';
      statusColor = AppTheme.primaryBlue;
    } else if (status == 'live') {
      statusText = 'جارية الآن';
      statusColor = Colors.redAccent;
      isLive = true;
    } else if (status == 'finished') {
      statusText = 'مكتملة';
      statusColor = Colors.white54;
    }

    final title = t['title'] ?? 'بطولة';
    final game = t['game'] ?? 'غير محدد';
    final maxTeams = (t['maxTeams'] is int) ? t['maxTeams'] as int : int.tryParse(t['maxTeams']?.toString() ?? '0') ?? 0;
    final registered = (t['registeredTeamsCount'] is int) ? t['registeredTeamsCount'] as int : int.tryParse(t['registeredTeamsCount']?.toString() ?? '0') ?? 0;
    final prize = t['prizePool'] ?? '0';
    final date = t['startDate'] ?? '';

    final double fillPercentage = maxTeams > 0 ? (registered / maxTeams).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => TournamentDetailsScreen(tournament: t),
        ));
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161D2B), Color(0xFF101520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLive ? Colors.redAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLive ? Colors.red : AppTheme.primaryBlue).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row (Status + Prize)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLive) ...[
                      const Icon(Icons.circle, color: Colors.redAccent, size: 7),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$prize',
                      style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 10),

          // Metadata Chips Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sports_esports_rounded, size: 14, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Text(game, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (date.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(date, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Registration Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الفرق المسجلة: $registered من $maxTeams',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  Text(
                    '${(fillPercentage * 100).toInt()}%',
                    style: TextStyle(
                      color: fillPercentage >= 1.0 ? Colors.redAccent : AppTheme.primaryBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: fillPercentage,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    fillPercentage >= 1.0 ? Colors.redAccent : AppTheme.primaryBlue,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Action Buttons (iOS Rounded Squircles)
          Row(
            children: [
              if (!widget.isGuest && (status == 'upcoming' || status == 'open')) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TournamentRegistrationScreen(tournamentData: t),
                        ),
                      );
                    },
                    icon: const Icon(Icons.app_registration_rounded, size: 18),
                    label: const Text('تسجيل الفريق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BracketScreen(
                          tournamentTitle: title,
                          tournamentId: t['id'] ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_tree_rounded, size: 18, color: Colors.white70),
                  label: const Text('شجرة المباريات', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    backgroundColor: Colors.white.withValues(alpha: 0.03),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
