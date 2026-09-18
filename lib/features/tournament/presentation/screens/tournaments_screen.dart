import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'bracket_screen.dart';
import 'tournament_registration_screen.dart';

class TournamentsScreen extends StatefulWidget {
  final bool isGuest;
  const TournamentsScreen({Key? key, this.isGuest = false}) : super(key: key);

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  String _selectedGame = 'الكل';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('استكشف البطولات السودانية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
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
                // Search Input
                TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث عن بطولة أو تصفيات ولائية...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 16),

                // Game Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['الكل', 'PUBG Mobile', 'EA FC 25', 'Free Fire', 'Valorant'].map((game) {
                      final isSelected = _selectedGame == game;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(game, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGreen,
                          backgroundColor: AppTheme.cardDark,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedGame = game);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
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
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ في تحميل البطولات.'));
                }

                final tournaments = snapshot.data ?? [];

                if (tournaments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد بطولات حالياً',
                          style: TextStyle(fontSize: 18, color: Colors.white54),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'سيتم عرض البطولات هنا بمجرد أن يعلن عنها المشرفون.',
                          style: TextStyle(fontSize: 14, color: Colors.white38),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
    // Map status from Firestore ('upcoming', 'live', 'finished') to UI text and colors
    String statusText = 'غير محدد';
    Color statusColor = Colors.grey;
    bool isLive = false;
    
    final status = t['status']?.toString().toLowerCase() ?? '';
    
    if (status == 'upcoming' || status == 'open') {
      statusText = 'التسجيل مفتوح';
      statusColor = AppTheme.primaryGreen;
    } else if (status == 'live') {
      statusText = 'جارية الآن';
      statusColor = Colors.red;
      isLive = true;
    } else if (status == 'finished') {
      statusText = 'مكتملة';
      statusColor = Colors.grey;
    }

    final title = t['title'] ?? 'بطولة';
    final game = t['game'] ?? 'غير محدد';
    final maxTeams = t['maxTeams'] ?? 0;
    final registered = t['registeredTeamsCount'] ?? 0;
    final teamsText = '$registered / $maxTeams فريق';
    final prize = t['prizePool'] ?? '0';
    final date = t['startDate'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? Colors.red.withOpacity(0.4) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    if (isLive) ...[
                      const Icon(Icons.circle, color: Colors.red, size: 8),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🏆 $prize',
                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.sports_esports, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Text(game, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.group, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Text(teamsText, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Text(date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!widget.isGuest && (status == 'upcoming' || status == 'open')) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TournamentRegistrationScreen(tournamentData: t),
                        ),
                      );
                    },
                    icon: const Icon(Icons.app_registration, size: 18),
                    label: const Text('تسجيل الفريق'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BracketScreen(tournamentTitle: title),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_tree_outlined, size: 18, color: Colors.white),
                  label: const Text('شجرة المباريات', style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
