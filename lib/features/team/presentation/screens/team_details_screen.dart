import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class TeamDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> team;
  const TeamDetailsScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final teamId = team['id'] ?? '';
    final teamName = team['name'] ?? 'فريق';
    final game = team['game'] ?? '';
    final points = team['points'] ?? 0;
    final leaderId = team['leaderId'] ?? '';
    final roster = (team['roster'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLeader = currentUid == leaderId;

    Future<void> joinTeam() async {
      try {
        await FirestoreService().joinTeam(
          teamId,
          currentUid,
          {'uid': currentUid, 'name': FirebaseAuth.instance.currentUser?.displayName ?? 'لاعب', 'ign': ''},
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('انضممت للفريق بنجاح!'), backgroundColor: AppTheme.primaryBlue),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue.withValues(alpha: 0.3), AppTheme.cardDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    child: Text(teamName.substring(0, 1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  ),
                  const SizedBox(height: 12),
                  Text(teamName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(game, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statChip(Icons.star, '$points نقطة', Colors.amber),
                      const SizedBox(width: 12),
                      _statChip(Icons.group, '${roster.length} عضو', AppTheme.primaryBlue),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Roster Section
            const Text('أعضاء الفريق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (roster.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('لا يوجد أعضاء بعد', style: TextStyle(color: Colors.white54))),
              )
            else
              ...roster.map((member) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: member['uid'] == leaderId
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      child: Icon(
                        member['uid'] == leaderId ? Icons.star : Icons.person,
                        color: member['uid'] == leaderId ? Colors.amber : Colors.white54,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member['name'] ?? 'لاعب', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if ((member['ign'] ?? '').isNotEmpty)
                            Text('IGN: ${member['ign']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (member['uid'] == leaderId)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: const Text('كابتن', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              )),
          ],
        ),
      ),
      bottomNavigationBar: !isLeader
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: joinTeam,
                  icon: const Icon(Icons.person_add),
                  label: const Text('انضم لهذا الفريق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }
}
