import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class OrganizerRefereesScreen extends StatelessWidget {
  const OrganizerRefereesScreen({super.key});

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
            return const Center(child: Text('لا يوجد حكام', style: TextStyle(color: Colors.white54, fontSize: 16)));
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
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.sports, color: Colors.black),
                  ),
                  title: Text(referee['displayName'] ?? 'حكم مجهول', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('البريد: ${referee['email'] ?? 'غير متوفر'}', style: const TextStyle(color: Colors.white54)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
