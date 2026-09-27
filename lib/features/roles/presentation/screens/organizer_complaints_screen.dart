import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class OrganizerComplaintsScreen extends StatelessWidget {
  OrganizerComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الاعتراضات والشكاوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDummyComplaint(context),
        backgroundColor: Colors.red,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onSurface),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getComplaintsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا توجد اعتراضات', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16)));
          }
          
          final complaints = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
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
                color: Theme.of(context).colorScheme.surface,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(12),
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
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(complaint['title'] ?? 'بدون عنوان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(complaint['description'] ?? 'لا يوجد تفاصيل', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status != 'resolved') ...[
                            TextButton.icon(
                              onPressed: () async {
                                await FirestoreService().updateComplaintStatus(complaint['id'], 'resolved');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تم تعليم الشكوى كمحلولة بنجاح ✅', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue),
                                  );
                                }
                              },
                              icon: Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              label: Text('حل الشكوى', style: TextStyle(color: Colors.green, fontSize: 12)),
                            ),
                            SizedBox(width: 4),
                          ],
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('تأكيد الحذف', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('هل أنت متأكد من رغبتك في حذف "$title"؟', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().deleteComplaint(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف الشكوى بنجاح ✅', style: TextStyle(color: Colors.black)),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل في حذف الشكوى ❌', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('حذف'),
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('إضافة شكوى تجريبية', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'العنوان', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              TextField(
                controller: descController,
                decoration: InputDecoration(labelText: 'التفاصيل', labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة الشكوى بنجاح', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في إضافة الشكوى', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)), backgroundColor: Colors.red));
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('إرسال'),
            ),
          ],
        );
      },
    );
  }
}
