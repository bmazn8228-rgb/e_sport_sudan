import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/storage_service.dart';
import 'package:e_sport_sudan/core/utils/validators.dart';
import 'package:e_sport_sudan/core/utils/connectivity_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';

class TournamentAdminDashboardScreen extends StatefulWidget {
  const TournamentAdminDashboardScreen({super.key});

  @override
  State<TournamentAdminDashboardScreen> createState() => _TournamentAdminDashboardScreenState();
}

class _TournamentAdminDashboardScreenState extends State<TournamentAdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showAddTournamentDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
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
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text('إضافة بطولة جديدة'),
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
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                                image: posterFile != null ? DecorationImage(image: FileImage(posterFile!), fit: BoxFit.cover) : null,
                              ),
                              child: posterFile == null ? Center(child: Text('اختر بوستر\nالبطولة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))) : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => pickImage(false, setState),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                                image: logoFile != null ? DecorationImage(image: FileImage(logoFile!), fit: BoxFit.contain) : null,
                              ),
                              child: logoFile == null ? Center(child: Text('اختر شعار\nاللعبة', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      validator: (v) => Validators.validateRequired(v, fieldName: 'اسم البطولة'),
                      decoration: InputDecoration(labelText: 'اسم البطولة'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: descriptionController,
                      validator: (v) => Validators.validateRequired(v, fieldName: 'وصف البطولة'),
                      decoration: InputDecoration(labelText: 'وصف البطولة (نبذة، قوانين، شروط)'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGame,
                      items: games.map((game) => DropdownMenuItem(value: game, child: Text(game))).toList(),
                      onChanged: (val) => selectedGame = val!,
                      decoration: InputDecoration(labelText: 'اللعبة'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: prizeController,
                      validator: (v) => Validators.validateRequired(v, fieldName: 'مجموع الجوائز'),
                      decoration: InputDecoration(labelText: 'مجموع الجوائز (مثال: 500,000 ج.س)'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: feeController,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validatePositiveNumber(v, fieldName: 'رسوم الدخول'),
                      decoration: InputDecoration(labelText: 'رسوم الدخول (رقم)'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: maxTeamsController,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validatePositiveNumber(v, fieldName: 'أقصى عدد للفرق'),
                      decoration: InputDecoration(labelText: 'أقصى عدد للفرق'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: playersPerTeamController,
                      keyboardType: TextInputType.number,
                      validator: (v) => Validators.validatePositiveNumber(v, fieldName: 'عدد اللاعبين لكل فريق'),
                      decoration: InputDecoration(labelText: 'عدد اللاعبين لكل فريق'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: dateController,
                      validator: (v) => Validators.validateRequired(v, fieldName: 'تاريخ البداية'),
                      decoration: InputDecoration(labelText: 'تاريخ البداية (مثال: 2025-10-15)'),
                    ),
                  ],
                ),
              ),
            ),
        actions: [
          if (!isUploading)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
            ),
          isUploading
              ? Padding(
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
                          SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.'), backgroundColor: Colors.red),
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
                      'description': descriptionController.text.trim(),
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
                          SnackBar(
                            content: Text('تمت إضافة البطولة بنجاح ✅', style: TextStyle(color: Colors.black)),
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isUploading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل في إضافة البطولة ❌', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                  child: Text('إضافة'),
                ),
        ],
      );
    },
  ));
}

  void _updateStatus(String tournamentId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تغيير حالة البطولة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.event_available, color: AppTheme.primaryBlue),
              title: Text('التسجيل مفتوح (Upcoming)'),
              onTap: () => _applyStatusChange(ctx, tournamentId, 'upcoming'),
            ),
            ListTile(
              leading: Icon(Icons.play_circle_filled, color: Colors.red),
              title: Text('جارية الآن (Live)'),
              onTap: () => _applyStatusChange(ctx, tournamentId, 'live'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.grey),
              title: Text('مكتملة (Finished)'),
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
          SnackBar(
            content: Text('تم تحديث حالة البطولة بنجاح ✅', style: TextStyle(color: Colors.black)),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث حالة البطولة ❌', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('تأكيد حذف البطولة', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('هل أنت متأكد من رغبتك في حذف بطولة "$title"؟ سيتم حذف جميع بياناتها نهائياً.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
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
                await _firestoreService.deleteTournament(tournamentId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم حذف البطولة بنجاح ✅', style: TextStyle(color: Colors.black)),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل في حذف البطولة ❌', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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

  void _showRegistrationsDialog(BuildContext context, String tournamentId, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text('الفرق المسجلة في: $title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getTournamentRegistrationsStream(tournamentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                  }
                  final registrations = snapshot.data ?? [];
                  if (registrations.isEmpty) {
                    return Center(
                      child: Text('لا توجد فرق مسجلة في هذه البطولة بعد', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                    );
                  }
                  return ListView.builder(
                    itemCount: registrations.length,
                    itemBuilder: (context, index) {
                      final reg = registrations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                          child: Text('${index + 1}', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(reg['teamName'] ?? 'فريق', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('القائد: ${reg['leaderName'] ?? 'كابتن'} • الهاتف: ${reg['contactPhone'] ?? 'غير متوفر'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                        trailing: Text('مسجل ✅', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrizeDistributionDialog(BuildContext context, String tournamentId, String title) {
    String? selectedLeaderId;
    final amountController = TextEditingController();
    bool isSubmitting = false;
    int selectedRank = 1; // 1: First, 2: Second, 3: Third

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final isKeyboardOpen = MediaQuery.of(ctx).viewInsets.bottom > 0;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ]
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('منصة التتويج والجوائز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Rank Selection
                Text('اختر المركز (الرتبة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildRankSelector(1, 'الأول', Colors.amber, selectedRank, () => setState(() => selectedRank = 1)),
                    SizedBox(width: 12),
                    _buildRankSelector(2, 'الثاني', Colors.grey[400]!, selectedRank, () => setState(() => selectedRank = 2)),
                    SizedBox(width: 12),
                    _buildRankSelector(3, 'الثالث', Colors.brown[300]!, selectedRank, () => setState(() => selectedRank = 3)),
                  ],
                ),
                SizedBox(height: 24),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getTournamentRegistrationsStream(tournamentId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                    }
                    final registrations = snapshot.data ?? [];
                    if (registrations.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('لا توجد فرق مسجلة لمنحهم الجائزة', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الفريق الفائز بالمركز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedLeaderId,
                          icon: Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryBlue),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.shield, color: _getRankColor(selectedRank)),
                          ),
                          hint: Text('اختر الفريق لتتويجه...'),
                          items: registrations.map((reg) {
                            return DropdownMenuItem<String>(
                              value: reg['leaderId'] as String?,
                              child: Text('${reg['teamName']} (كابتن: ${reg['leaderName']})', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedLeaderId = val);
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 24),

                Text('مبلغ الجائزة المخصص (ج.س)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'مثال: 250,000',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    prefixIcon: Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.payments, color: Colors.green),
                    ),
                    suffixText: 'ج.س',
                    suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                if (!isKeyboardOpen) SizedBox(height: 32) else SizedBox(height: 16),
                
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (selectedLeaderId == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الرجاء اختيار الفريق الفائز وتحديد مبلغ مالي صحيح ⚠️'), backgroundColor: Colors.red));
                      return;
                    }

                    setState(() => isSubmitting = true);
                    try {
                      String rankName = selectedRank == 1 ? 'الأول' : selectedRank == 2 ? 'الثاني' : 'الثالث';
                      await _firestoreService.distributePrizeManually(
                        targetUserId: selectedLeaderId!,
                        amount: amount,
                        tournamentName: '$title (المركز $rankName)',
                      );
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(child: Text('تم إيداع مبلغ $amount ج.س بنجاح في محفظة القائد! 🏆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: EdgeInsets.all(16),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التوزيع: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRankColor(selectedRank),
                    foregroundColor: selectedRank == 2 ? Colors.black : Colors.white,
                    elevation: 0,
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSubmitting
                      ? CircularProgressIndicator(color: selectedRank == 2 ? Colors.black : Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded),
                            SizedBox(width: 8),
                            Text('اعتماد وتحويل الجائزة للمحفظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.grey[400]!;
      case 3: return Colors.brown[400]!;
      default: return AppTheme.primaryBlue;
    }
  }

  Widget _buildRankSelector(int rank, String label, Color color, int selectedRank, VoidCallback onTap) {
    bool isSelected = rank == selectedRank;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1, offset: Offset(0, 4))
            ] : [],
          ),
          child: Column(
            children: [
              Icon(Icons.military_tech, color: isSelected ? (rank == 2 ? Colors.black87 : Colors.white) : color, size: 28),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? (rank == 2 ? Colors.black87 : Colors.white) : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userRole = doc.data()?['role'] as String?;
        });
      }
    }
  }

  bool get _isSuperAdmin {
    final email = FirebaseAuth.instance.currentUser?.email;
    return _userRole == 'super_admin' || email == 'superadmin@esportsudan.sd' || email == 'admin@esportsudan.sd';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة إدارة البطولات', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: _isSuperAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddTournamentDialog(context),
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.add, color: Colors.black),
            )
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getTournamentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل البطولات'));
          }

          final tournaments = snapshot.data ?? [];

          if (tournaments.isEmpty) {
            return Center(child: Text('لا توجد بطولات. اضغط على + للإضافة.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
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
                color: Theme.of(context).colorScheme.surface,
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(t['title'] ?? 'بدون اسم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('اللعبة: ${t['game']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                      Text('الجوائز: ${t['prizePool']} | الرسوم: ${t['entryFee']}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                      Text('الفرق: ${t['registeredTeamsCount']} / ${t['maxTeams']} (اللاعبين لكل فريق: ${t['playersPerTeam'] ?? 1})', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showRegistrationsDialog(context, t['id'], t['title'] ?? 'البطولة'),
                                  icon: Icon(Icons.people_outline, size: 16, color: AppTheme.primaryBlue),
                                  label: Text('المسجلين', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showPrizeDistributionDialog(context, t['id'], t['title'] ?? 'البطولة'),
                                  icon: Icon(Icons.monetization_on, size: 16, color: Colors.amber),
                                  label: Text('توزيع الجائزة', style: TextStyle(color: Colors.amber, fontSize: 12)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _updateStatus(t['id'], status),
                                  icon: Icon(Icons.edit, size: 16),
                                  label: Text('الحالة', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                                ),
                                TextButton.icon(
                                  onPressed: () => _confirmDeleteTournament(t['id'], t['title'] ?? 'البطولة'),
                                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  label: Text('حذف', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                ),
                              ],
                            ),
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
