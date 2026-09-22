import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/storage_service.dart';
import 'package:e_sport_sudan/core/utils/validators.dart';
import 'package:e_sport_sudan/core/utils/connectivity_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';

class TournamentAdminDashboardScreen extends StatefulWidget {
  const TournamentAdminDashboardScreen({super.key});

  @override
  State<TournamentAdminDashboardScreen> createState() => _TournamentAdminDashboardScreenState();
}

class _TournamentAdminDashboardScreenState extends State<TournamentAdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showAddTournamentDialog(BuildContext context) {
    final titleController = TextEditingController();
    final prizeController = TextEditingController();
    final feeController = TextEditingController();
    final maxTeamsController = TextEditingController();
    final playersPerTeamController = TextEditingController();
    final dateController = TextEditingController();
    String selectedGame = 'PUBG Mobile';

    final games = ['PUBG Mobile', 'EA FC 25', 'Free Fire', 'Valorant'];

    File? posterFile;
    File? logoFile;
    bool isUploading = false;

    Future<void> pickImage(bool isPoster, StateSetter setState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (isPoster) {
            posterFile = File(pickedFile.path);
          } else {
            logoFile = File(pickedFile.path);
          }
        });
      }
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text('إضافة بطولة جديدة'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => pickImage(true, setState),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                                image: posterFile != null ? DecorationImage(image: FileImage(posterFile!), fit: BoxFit.cover) : null,
                              ),
                              child: posterFile == null ? const Center(child: Text('اختر بوستر\nالبطولة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))) : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => pickImage(false, setState),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                                image: logoFile != null ? DecorationImage(image: FileImage(logoFile!), fit: BoxFit.contain) : null,
                              ),
                              child: logoFile == null ? const Center(child: Text('اختر شعار\nاللعبة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      validator: (v) => Validators.validateRequired(v, fieldName: 'اسم البطولة'),
                      decoration: const InputDecoration(labelText: 'اسم البطولة'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGame,
                      items: games.map((game) => DropdownMenuItem(value: game, child: Text(game))).toList(),
                      onChanged: (val) => selectedGame = val!,
                      decoration: const InputDecoration(labelText: 'اللعبة'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: prizeController,
                      validator: (v) => Validators.validateRequired(v, fieldName: 'مجموع الجوائز'),
                      decoration: const InputDecoration(labelText: 'مجموع الجوائز (مثال: 500,000 ج.س)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: feeController,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validatePositiveNumber(v, fieldName: 'رسوم الدخول'),
                      decoration: const InputDecoration(labelText: 'رسوم الدخول (رقم)'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: maxTeamsController,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validatePositiveNumber(v, fieldName: 'أقصى عدد للفرق'),
                      decoration: const InputDecoration(labelText: 'أقصى عدد للفرق'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: playersPerTeamController,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validatePositiveNumber(v, fieldName: 'عدد اللاعبين لكل فريق'),
                      decoration: const InputDecoration(labelText: 'عدد اللاعبين لكل فريق'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: dateController,
                      validator: (v) => Validators.validateRequired(v, fieldName: 'تاريخ البداية'),
                      decoration: const InputDecoration(labelText: 'تاريخ البداية (مثال: 2025-10-15)'),
                    ),
                  ],
                ),
              ),
            ),
        actions: [
          if (!isUploading)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
          isUploading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                )
              : ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    if (!await ConnectivityHelper.hasInternetConnection()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.'), backgroundColor: Colors.red),
                        );
                      }
                      return;
                    }

                    setState(() {
                      isUploading = true;
                    });

                    String? posterUrl;
                    String? logoUrl;

                    if (posterFile != null) {
                      posterUrl = await StorageService().uploadImage(posterFile!, 'tournaments/posters');
                    }
                    if (logoFile != null) {
                      logoUrl = await StorageService().uploadImage(logoFile!, 'tournaments/logos');
                    }

                    final tournamentData = {
                      'title': titleController.text.trim(),
                      'game': selectedGame,
                      'prizePool': prizeController.text.trim(),
                      'entryFee': int.tryParse(feeController.text.trim()) ?? 0,
                      'maxTeams': int.tryParse(maxTeamsController.text.trim()) ?? 0,
                      'playersPerTeam': int.tryParse(playersPerTeamController.text.trim()) ?? 1,
                      'registeredTeamsCount': 0,
                      'startDate': dateController.text.trim(),
                      'status': 'upcoming',
                      'posterUrl': posterUrl ?? '',
                      'logoUrl': logoUrl ?? '',
                    };

                    try {
                      await _firestoreService.createTournament(tournamentData);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تمت إضافة البطولة بنجاح ✅', style: TextStyle(color: Colors.black)),
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isUploading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('فشل في إضافة البطولة ❌', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  child: const Text('إضافة'),
                ),
        ],
      );
    },
  ));
}

  void _updateStatus(String tournamentId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تغيير حالة البطولة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event_available, color: AppTheme.primaryBlue),
              title: const Text('التسجيل مفتوح (Upcoming)'),
              onTap: () => _applyStatusChange(ctx, tournamentId, 'upcoming'),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_filled, color: Colors.red),
              title: const Text('جارية الآن (Live)'),
              onTap: () => _applyStatusChange(ctx, tournamentId, 'live'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.grey),
              title: const Text('مكتملة (Finished)'),
              onTap: () => _applyStatusChange(ctx, tournamentId, 'finished'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyStatusChange(BuildContext bottomSheetContext, String tournamentId, String newStatus) async {
    Navigator.pop(bottomSheetContext);
    try {
      await _firestoreService.updateTournamentStatus(tournamentId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة البطولة بنجاح ✅', style: TextStyle(color: Colors.black)),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحديث حالة البطولة ❌', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDeleteTournament(String tournamentId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('تأكيد حذف البطولة', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من رغبتك في حذف بطولة "$title"؟ سيتم حذف جميع بياناتها نهائياً.', style: const TextStyle(color: Colors.white70)),
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
                await _firestoreService.deleteTournament(tournamentId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف البطولة بنجاح ✅', style: TextStyle(color: Colors.black)),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فشل في حذف البطولة ❌', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة إدارة البطولات', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTournamentDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getTournamentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في تحميل البطولات'));
          }

          final tournaments = snapshot.data ?? [];

          if (tournaments.isEmpty) {
            return const Center(child: Text('لا توجد بطولات. اضغط على + للإضافة.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final t = tournaments[index];
              final status = t['status'] ?? 'غير معروف';
              Color statusColor = Colors.grey;
              String statusText = status;
              if (status == 'upcoming' || status == 'open') {
                statusColor = AppTheme.primaryBlue;
                statusText = 'التسجيل مفتوح';
              } else if (status == 'live') {
                statusColor = Colors.red;
                statusText = 'جارية';
              } else if (status == 'finished') {
                statusColor = Colors.grey;
                statusText = 'مكتملة';
              }

              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(t['title'] ?? 'بدون اسم', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('اللعبة: ${t['game']}', style: const TextStyle(color: Colors.white70)),
                      Text('الجوائز: ${t['prizePool']} | الرسوم: ${t['entryFee']}', style: const TextStyle(color: Colors.white70)),
                      Text('الفرق: ${t['registeredTeamsCount']} / ${t['maxTeams']} (اللاعبين لكل فريق: ${t['playersPerTeam'] ?? 1})', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _confirmDeleteTournament(t['id'], t['title'] ?? 'البطولة'),
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            label: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _updateStatus(t['id'], status),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('تغيير الحالة'),
                            style: TextButton.styleFrom(foregroundColor: Colors.orange),
                          ),
                        ],
                      )
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
}
