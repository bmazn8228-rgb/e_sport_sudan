import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';

class BracketScreen extends StatefulWidget {
  final String tournamentTitle;

  const BracketScreen({Key? key, required this.tournamentTitle}) : super(key: key);

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

  final List<Map<String, dynamic>> _quarterFinals = [
    {
      'id': 'M1',
      'teamA': 'صقور النيل',
      'teamB': 'فرسان المقرن',
      'scoreA': 2,
      'scoreB': 1,
      'winner': 'teamA',
      'status': 'انتهت',
      'time': 'أمس',
    },
    {
      'id': 'M2',
      'teamA': 'أسود توتي',
      'teamB': 'نسور كوستي',
      'scoreA': 3,
      'scoreB': 0,
      'winner': 'teamA',
      'status': 'انتهت',
      'time': 'أمس',
    },
    {
      'id': 'M3',
      'teamA': 'أبطال مدني',
      'teamB': 'ذئاب بورتسودان',
      'scoreA': 1,
      'scoreB': 1,
      'winner': null,
      'status': 'جارية الآن',
      'time': 'شوط إضافي',
    },
    {
      'id': 'M4',
      'teamA': 'ريد نايل إي سبورت',
      'teamB': 'فايكنج الخرطوم',
      'scoreA': 0,
      'scoreB': 0,
      'winner': null,
      'status': 'قادمة',
      'time': 'اليوم 8:00 م',
    },
  ];

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
            Text(widget.tournamentTitle, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
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
                    selectedColor: AppTheme.primaryGreen,
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _quarterFinals.length,
              itemBuilder: (context, index) {
                final match = _quarterFinals[index];
                return _buildMatchCard(match);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final bool isLive = match['status'] == 'جارية الآن';

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
                  'مباراة #${match['id']}',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLive ? Colors.red.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match['status'],
                    style: TextStyle(
                      color: isLive ? Colors.red : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  match['time'],
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
                  match['teamA'],
                  match['scoreA'],
                  isWinner: match['winner'] == 'teamA',
                ),
                const SizedBox(height: 10),
                _buildTeamRow(
                  match['teamB'],
                  match['scoreB'],
                  isWinner: match['winner'] == 'teamB',
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
                color: isWinner ? AppTheme.primaryGreen : Colors.transparent,
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
            color: isWinner ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.black,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isWinner ? AppTheme.primaryGreen : Colors.white10,
            ),
          ),
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isWinner ? AppTheme.primaryGreen : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
