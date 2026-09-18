import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class OrganizerTeamsScreen extends StatelessWidget {
  const OrganizerTeamsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفرق المشاركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getAllTeamsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد فرق', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }
          
          final teams = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
                    child: Icon(Icons.shield, color: Colors.black),
                  ),
                  title: Text(team['name'] ?? 'فريق مجهول', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('اللعبة: ${team['game'] ?? 'غير محدد'} | النقاط: ${team['points'] ?? 0}', style: const TextStyle(color: Colors.white54)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
