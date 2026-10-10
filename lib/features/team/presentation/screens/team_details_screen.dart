import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final isMember = isLeader || roster.any((m) => m['uid'] == currentUid);
    final joinType = team['joinType'] ?? 'public';
    final pendingRequests = (team['pendingRequests'] as List?) ?? [];
    final hasRequested = pendingRequests.any((req) => req is Map && req['uid'] == currentUid);

    Future<void> joinTeam() async {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        final userDoc = await FirestoreService().getUser(currentUid);
        if (userDoc?.teamId != null && userDoc!.teamId!.isNotEmpty && userDoc.teamId != teamId) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('أنت منضم بالفعل إلى فريق آخر! يجب مغادرة فريقك الحالي أولاً.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final displayName = (userDoc?.displayName != null && userDoc!.displayName.isNotEmpty)
            ? userDoc.displayName
            : (currentUser.displayName ?? 'لاعب');

        final rosterData = {
          'uid': currentUid,
          'name': displayName,
          'displayName': displayName,
          'email': currentUser.email ?? '',
          'ign': userDoc?.ign ?? '',
          'role': 'عضو',
          'joinedAt': DateTime.now().toIso8601String(),
        };

        if (joinType == 'approval') {
          rosterData['status'] = 'pending';
          rosterData['requestedAt'] = DateTime.now().toIso8601String();
          await FirestoreService().requestToJoinTeam(teamId, rosterData, teamName: teamName);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم إرسال طلب الانضمام لقائد الفريق بنجاح! ⏳'), backgroundColor: Colors.orange.shade700),
            );
            Navigator.pop(context, true);
          }
        } else {
          await FirestoreService().joinTeam(teamId, currentUid, rosterData);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('انضممت للفريق بنجاح! 🏆'), backgroundColor: AppTheme.primaryBlue),
            );
            Navigator.pop(context, true);
          }
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
        title: Text(teamName, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue.withValues(alpha: 0.3), Theme.of(context).colorScheme.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final logoUrl = (team['logoUrl'] ?? '').toString();
                      return CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        backgroundImage: logoUrl.isNotEmpty ? CachedNetworkImageProvider(logoUrl) : null,
                        child: logoUrl.isEmpty
                            ? Text(teamName.substring(0, 1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))
                            : null,
                      );
                    },
                  ),
                  SizedBox(height: 12),
                  Text(teamName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  if (teamId.isNotEmpty) ...[
                    SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: teamId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم نسخ معرف الفريق: $teamId'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tag_rounded, size: 13, color: AppTheme.primaryBlue),
                            SizedBox(width: 4),
                            Text('ID: $teamId', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                            SizedBox(width: 6),
                            Icon(Icons.copy_rounded, size: 12, color: AppTheme.primaryBlue),
                          ],
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 6),
                  Text(game, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 14)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statChip(Icons.star, '$points نقطة', Colors.amber),
                      SizedBox(width: 12),
                      _statChip(Icons.group, '${roster.length} عضو', AppTheme.primaryBlue),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Roster Section
            Text('أعضاء الفريق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            if (roster.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('لا يوجد أعضاء بعد', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)))),
              )
            else
              ...roster.map((member) => Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: member['uid'] == leaderId
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                      child: Icon(
                        member['uid'] == leaderId ? Icons.star : Icons.person,
                        color: member['uid'] == leaderId ? Colors.amber : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member['name'] ?? 'لاعب', style: TextStyle(fontWeight: FontWeight.bold)),
                          if ((member['ign'] ?? '').isNotEmpty)
                            Text('IGN: ${member['ign']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                        ],
                      ),
                    ),
                    if (member['uid'] == leaderId)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Text('كابتن', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              )),
          ],
        ),
      ),
      bottomNavigationBar: !isMember
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: hasRequested
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.hourglass_top_rounded, color: Colors.orangeAccent),
                        label: const Text('طلبك قيد الانتظار ⏳', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(color: Colors.orangeAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: joinTeam,
                        icon: Icon(joinType == 'approval' ? Icons.send_rounded : Icons.person_add),
                        label: Text(
                          joinType == 'approval' ? 'طلب انضمام للفريق 🔒' : 'انضم لهذا الفريق ⚡',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: joinType == 'approval' ? Colors.orangeAccent : AppTheme.primaryBlue,
                          foregroundColor: joinType == 'approval' ? Colors.black : Colors.white,
                          minimumSize: const Size(double.infinity, 52),
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
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }
}
