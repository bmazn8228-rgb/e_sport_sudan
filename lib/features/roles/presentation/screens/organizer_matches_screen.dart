import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class OrganizerMatchesScreen extends StatelessWidget {
  const OrganizerMatchesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المباريات المكتملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getAllMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }
          
          final matches = snapshot.data?.where((m) => m['status'] == 'completed').toList() ?? [];
          
          if (matches.isEmpty) {
            return const Center(child: Text('لا توجد مباريات مكتملة', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.sports_score, color: Colors.black),
                  ),
                  title: Text('${match['teamA'] ?? 'فريق أ'} VS ${match['teamB'] ?? 'فريق ب'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('النتيجة: ${match['scoreA'] ?? 0} - ${match['scoreB'] ?? 0}', style: const TextStyle(color: Colors.white54)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
