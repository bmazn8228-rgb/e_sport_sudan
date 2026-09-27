import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class OrganizerRefereesScreen extends StatelessWidget {
  const OrganizerRefereesScreen({super.key});

  void _showAssignMatchDialog(BuildContext context, Map<String, dynamic> referee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports, color: Colors.blue),
                const SizedBox(width: 8),
                Text('تعيين الحكم: ${referee['displayName'] ?? 'حكم'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('اختر مباراة لتوكيل هذا الحكم بإدارتها وتوثيق نتيجتها:', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getAllMatchesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }
                final scheduledMatches = (snapshot.data ?? []).where((m) => m['status'] == 'scheduled').toList();
                if (scheduledMatches.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('لا توجد مباريات مجدولة بانتظار تعيين حكام', style: TextStyle(color: Colors.white54))),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: scheduledMatches.length,
                  itemBuilder: (context, index) {
                    final match = scheduledMatches[index];
                    final isAlreadyAssigned = match['refereeId'] == referee['id'];

                    return ListTile(
                      tileColor: isAlreadyAssigned ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(isAlreadyAssigned ? Icons.check_circle : Icons.sports_score, color: isAlreadyAssigned ? Colors.blue : Colors.white54),
                      title: Text('${match['teamA']} VS ${match['teamB']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${match['round'] ?? 'مباراة'} • ${match['time'] ?? ''}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAlreadyAssigned ? Colors.grey : AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: isAlreadyAssigned
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                try {
                                  await FirestoreService().assignRefereeToMatch(
                                    match['id'],
                                    referee['id'],
                                    referee['displayName'] ?? 'حكم معتمد',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم تعيين ${referee['displayName']} لإدارة المباراة بنجاح ✅', style: const TextStyle(color: Colors.black)),
                                        backgroundColor: AppTheme.primaryBlue,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                        child: Text(isAlreadyAssigned ? 'معيّن مسبقاً' : 'تعيين', style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حكام الساحة النشطين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUsersByRoleStream('referee'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد حكام معتمدين حالياً', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }

          final referees = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: referees.length,
            itemBuilder: (context, index) {
              final referee = referees[index];
              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.sports, color: Colors.black),
                  ),
                  title: Text(referee['displayName'] ?? 'حكم مجهول', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('البريد: ${referee['email'] ?? 'غير متوفر'}\nالحالة: معتمد من الاتحاد السوداني 🇸🇩', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  isThreeLine: true,
                  trailing: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _showAssignMatchDialog(context, referee),
                    icon: const Icon(Icons.assignment_ind, size: 16, color: Colors.blue),
                    label: const Text('توكيل مباراة', style: TextStyle(color: Colors.blue, fontSize: 11)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
