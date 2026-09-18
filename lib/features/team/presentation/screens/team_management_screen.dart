import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final List<Map<String, dynamic>> _roster = [
    {'name': 'أحمد علي عثمان', 'ign': 'Falcon_Leader', 'role': 'قائد الفريق / IGL', 'verified': true, 'isLeader': true},
    {'name': 'محمد عثمان البشير', 'ign': 'Falcon_Sniper', 'role': 'Assault / قناص', 'verified': true, 'isLeader': false},
    {'name': 'يوسف إبراهيم الطيب', 'ign': 'Falcon_Tig', 'role': 'Support / دعم', 'verified': true, 'isLeader': false},
    {'name': 'خالد طارق المجذوب', 'ign': 'Falcon_Sudan', 'role': 'Entry Fragger', 'verified': true, 'isLeader': false},
    {'name': 'سامي حسن النور', 'ign': 'Falcon_Sub', 'role': 'احتياطي معتمد', 'verified': false, 'isLeader': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة الفريق التنافسي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Profile Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGreen),
                    ),
                    child: const Icon(Icons.sports_kabaddi, size: 36, color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('صقور النيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 16),
                          ],
                        ),
                        const Text('Nile Falcons Esports • الخرطوم', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('الترتيب: #1 قومياً 🏆', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Team Quick Stats
            Row(
              children: [
                _buildStatBox('المباريات', '32', Icons.sports_esports),
                const SizedBox(width: 10),
                _buildStatBox('الانتصارات', '28', Icons.emoji_events, color: AppTheme.primaryGreen),
                const SizedBox(width: 10),
                _buildStatBox('نسبة الفوز', '87.5%', Icons.trending_up, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // Roster Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('قائمة اللاعبين والتشكيلة (5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add, size: 16, color: AppTheme.primaryGreen),
                  label: const Text('إضافة لاعب', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Roster List
            ..._roster.map((player) => _buildPlayerCard(player)),

            const SizedBox(height: 20),

            // Team Actions
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_document),
              label: const Text('تعديل التشكيلة الرسمية للبطولة القادمة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val, IconData icon, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player['isLeader'] ? AppTheme.primaryGreen.withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: player['isLeader'] ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.white10,
                child: Icon(
                  player['isLeader'] ? Icons.star : Icons.person,
                  color: player['isLeader'] ? AppTheme.primaryGreen : Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(player['ign'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (player['verified']) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 14),
                      ],
                    ],
                  ),
                  Text(player['name'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(player['role'], style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white54, size: 18),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
