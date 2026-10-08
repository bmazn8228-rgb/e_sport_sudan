import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/models/news_model.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';

class AdminNewsManagementScreen extends StatefulWidget {
  const AdminNewsManagementScreen({Key? key}) : super(key: key);

  @override
  _AdminNewsManagementScreenState createState() => _AdminNewsManagementScreenState();
}

class _AdminNewsManagementScreenState extends State<AdminNewsManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddNewsDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final imageUrlController = TextEditingController();
    String category = 'أخبار وبلاغات الاتحاد';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('إضافة خبر جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'عنوان الخبر', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(labelText: 'محتوى الخبر', border: OutlineInputBorder()),
                  maxLines: 4,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: imageUrlController,
                  decoration: InputDecoration(labelText: 'رابط الصورة (اختياري)', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
                  items: ['أخبار وبلاغات الاتحاد', 'تحديثات البطولات', 'أخبار عامة'].map((String val) {
                    return DropdownMenuItem(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  NotificationService.showCustomToast(context, title: 'خطأ', message: 'يرجى تعبئة العنوان والمحتوى', type: ToastType.urgent);
                  return;
                }
                
                final user = FirebaseAuth.instance.currentUser;
                final news = NewsModel(
                  id: '',
                  title: titleController.text,
                  content: contentController.text,
                  imageUrl: imageUrlController.text.isNotEmpty ? imageUrlController.text : null,
                  category: category,
                  createdAt: DateTime.now(),
                  authorId: user?.uid ?? 'admin',
                  authorName: user?.displayName ?? 'الإدارة',
                );

                try {
                  await _firestoreService.addNews(news);
                  if (context.mounted) {
                    Navigator.pop(context);
                    NotificationService.showCustomToast(context, title: 'نجاح', message: 'تم نشر الخبر بنجاح', type: ToastType.success);
                  }
                } catch (e) {
                  if (context.mounted) {
                    NotificationService.showCustomToast(context, title: 'خطأ', message: 'فشل في نشر الخبر، تحقق من الصلاحيات أو الاتصال', type: ToastType.urgent);
                  }
                }
              },
              child: Text('نشر الخبر'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الأخبار', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNewsDialog,
        icon: Icon(Icons.add),
        label: Text('إضافة خبر'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: StreamBuilder<List<NewsModel>>(
        stream: _firestoreService.getNewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          
          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) return Center(child: Text('لا توجد أخبار منشورة'));

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return Card(
                color: Theme.of(context).colorScheme.surface,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(news.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${DateFormat('yyyy/MM/dd').format(news.createdAt)} - ${news.authorName}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      try {
                        await _firestoreService.deleteNews(news.id);
                        if (context.mounted) {
                          NotificationService.showCustomToast(context, title: 'حذف', message: 'تم حذف الخبر بنجاح', type: ToastType.success);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          NotificationService.showCustomToast(context, title: 'خطأ', message: 'فشل في حذف الخبر', type: ToastType.urgent);
                        }
                      }
                    },
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
