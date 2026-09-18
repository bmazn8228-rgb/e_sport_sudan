import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class OrganizerComplaintsScreen extends StatelessWidget {
  const OrganizerComplaintsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاعتراضات والشكاوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDummyComplaint(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getComplaintsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد اعتراضات', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }
          
          final complaints = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.warning_amber, color: Colors.white),
                  ),
                  title: Text(complaint['title'] ?? 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(complaint['description'] ?? 'لا يوجد تفاصيل', style: const TextStyle(color: Colors.white54)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addDummyComplaint(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final descController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('إضافة شكوى تجريبية', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'العنوان', labelStyle: TextStyle(color: Colors.white54)),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'التفاصيل', labelStyle: TextStyle(color: Colors.white54)),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && descController.text.isNotEmpty) {
                  await FirestoreService().addComplaint({
                    'title': titleController.text,
                    'description': descController.text,
                    'status': 'pending',
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('إرسال'),
            ),
          ],
        );
      },
    );
  }
}
