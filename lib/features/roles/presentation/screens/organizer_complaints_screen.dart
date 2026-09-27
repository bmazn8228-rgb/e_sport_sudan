import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class OrganizerComplaintsScreen extends StatelessWidget {
  const OrganizerComplaintsScreen({super.key});

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
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
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
              final status = complaint['status'] ?? 'pending';
              Color statusColor = Colors.orange;
              String statusLabel = 'قيد المراجعة';
              if (status == 'resolved') {
                statusColor = Colors.green;
                statusLabel = 'تم الحل ✅';
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusLabel = 'مرفوضة ❌';
              }

              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: statusColor.withValues(alpha: 0.2),
                                  child: Icon(Icons.warning_amber, color: statusColor, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(complaint['title'] ?? 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(complaint['description'] ?? 'لا يوجد تفاصيل', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status != 'resolved') ...[
                            TextButton.icon(
                              onPressed: () async {
                                await FirestoreService().updateComplaintStatus(complaint['id'], 'resolved');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم تعليم الشكوى كمحلولة بنجاح ✅', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              label: const Text('حل الشكوى', style: TextStyle(color: Colors.green, fontSize: 12)),
                            ),
                            const SizedBox(width: 4),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                            tooltip: 'حذف الشكوى',
                            onPressed: () => _confirmDeleteComplaint(context, complaint['id'], complaint['title'] ?? 'الشكوى'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteComplaint(BuildContext context, String? id, String title) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من رغبتك في حذف "$title"؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().deleteComplaint(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الشكوى بنجاح ✅', style: TextStyle(color: Colors.black)),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فشل في حذف الشكوى ❌', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
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
                  try {
                    await FirestoreService().addComplaint({
                      'title': titleController.text,
                      'description': descController.text,
                      'status': 'pending',
                      'date': DateTime.now().toIso8601String(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الشكوى بنجاح', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في إضافة الشكوى', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                    }
                  }
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
