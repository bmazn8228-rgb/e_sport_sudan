import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class BracketScreen extends StatefulWidget {
  final String tournamentTitle;
  final String tournamentId;

  const BracketScreen({
    super.key,
    required this.tournamentTitle,
    required this.tournamentId,
  });

  @override
  State<BracketScreen> createState() => _BracketScreenState();
}

class _BracketScreenState extends State<BracketScreen> {
  int _selectedStageIndex = 1; // Quarter Finals by default

  final List<String> _stages = [
    'ثمن النهائي (16)',
    'ربع النهائي (8)',
    'نصف النهائي (4)',
    'النهائي 🏆',
  ];

  final List<Map<String, dynamic>> _quarterFinals = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('شجرة المباريات والتصفيات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.tournamentTitle, style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stages Tab Selector
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stages.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedStageIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(_stages[index], style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue,
                    backgroundColor: AppTheme.cardDark,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStageIndex = index);
                    },
                  ),
                );
              },
            ),
          ),

          // Matches List / Tree
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getTournamentMatchesStream(widget.tournamentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }
                
                final matches = snapshot.data ?? [];
                
                // Filter matches based on selected stage
                final stageName = _stages[_selectedStageIndex];
                final stageMatches = matches.where((m) => m['stage'] == stageName).toList();

                if (stageMatches.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد مباريات في هذه المرحلة حالياً',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stageMatches.length,
                  itemBuilder: (context, index) {
                    return _buildMatchCard(stageMatches[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final String status = match['status'] ?? 'غير محدد';
    final bool isLive = status == 'جارية الآن' || status == 'live';
    final String matchId = match['id'] ?? '...';
    final String time = match['time'] ?? 'غير محدد';

    final String teamA = match['teamA'] ?? 'فريق A';
    final int scoreA = match['scoreA'] ?? 0;
    
    final String teamB = match['teamB'] ?? 'فريق B';
    final int scoreB = match['scoreB'] ?? 0;
    
    final String? winner = match['winner'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? Colors.red.withOpacity(0.6) : Colors.white12,
          width: isLive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Match Top Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'مباراة #$matchId',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isLive ? Colors.red : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // Teams
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildTeamRow(
                  teamA,
                  scoreA,
                  isWinner: winner == 'teamA',
                ),
                const SizedBox(height: 10),
                _buildTeamRow(
                  teamB,
                  scoreB,
                  isWinner: winner == 'teamB',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String teamName, int score, {required bool isWinner}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: isWinner ? AppTheme.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.shield_outlined, size: 20, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              teamName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isWinner ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.black,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isWinner ? AppTheme.primaryBlue : Colors.white10,
            ),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isWinner ? AppTheme.primaryBlue : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
