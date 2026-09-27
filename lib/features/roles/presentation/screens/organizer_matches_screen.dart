import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizerMatchesScreen extends StatefulWidget {
  const OrganizerMatchesScreen({super.key});

  @override
  State<OrganizerMatchesScreen> createState() => _OrganizerMatchesScreenState();
}

class _OrganizerMatchesScreenState extends State<OrganizerMatchesScreen> {
  String _selectedStatus = 'all';

  void _confirmDeleteMatch(BuildContext context, String matchId, String matchTitle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('تأكيد حذف المباراة', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من رغبتك في حذف "$matchTitle"؟', style: const TextStyle(color: Colors.white70)),
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
                await FirestoreService().deleteMatch(matchId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف المباراة بنجاح ✅', style: TextStyle(color: Colors.black)),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
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

  void _showAddMatchDialog(BuildContext context) {
    final teamAController = TextEditingController();
    final teamBController = TextEditingController();
    final roundController = TextEditingController(text: 'دور المجموعات');
    final timeController = TextEditingController(text: 'اليوم 20:00');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة مباراة يدوياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: teamAController,
                decoration: const InputDecoration(labelText: 'اسم الفريق أ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teamBController,
                decoration: const InputDecoration(labelText: 'اسم الفريق ب', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roundController,
                decoration: const InputDecoration(labelText: 'الدور / الجولة', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'الوقت والتاريخ', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: isSaving ? null : () async {
                    if (teamAController.text.trim().isEmpty || teamBController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى كتابة أسماء الفريقين'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    setSheetState(() => isSaving = true);
                    try {
                      await FirestoreService().createMatch({
                        'teamA': teamAController.text.trim(),
                        'teamB': teamBController.text.trim(),
                        'scoreA': 0,
                        'scoreB': 0,
                        'status': 'scheduled',
                        'round': roundController.text.trim(),
                        'time': timeController.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت إضافة المباراة بنجاح ✅', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue),
                        );
                      }
                    } catch (e) {
                      setSheetState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: Text(isSaving ? 'جاري الحفظ...' : 'إضافة المباراة 🚀', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول ومباريات البطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMatchDialog(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'كافة المباريات'),
                const SizedBox(width: 8),
                _buildFilterChip('scheduled', 'المجدولة'),
                const SizedBox(width: 8),
                _buildFilterChip('live', 'جارية الآن 🔴'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'المكتملة ✅'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getAllMatchesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                var matches = snapshot.data ?? [];
                if (_selectedStatus != 'all') {
                  matches = matches.where((m) => m['status'] == _selectedStatus).toList();
                }

                if (matches.isEmpty) {
                  return const Center(child: Text('لا توجد مباريات مطابقة للفلتر', style: TextStyle(color: Colors.white54, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    final matchId = match['id'] ?? '';
                    final teamA = match['teamA'] ?? 'فريق أ';
                    final teamB = match['teamB'] ?? 'فريق ب';
                    final scoreA = match['scoreA'] ?? 0;
                    final scoreB = match['scoreB'] ?? 0;
                    final status = match['status'] ?? 'scheduled';
                    final round = match['round'] ?? 'مباراة';
                    final time = match['time'] ?? '';

                    Color statusColor = Colors.grey;
                    String statusLabel = 'مجدولة';
                    if (status == 'live') {
                      statusColor = Colors.red;
                      statusLabel = 'مباشر الآن 🔴';
                    } else if (status == 'completed') {
                      statusColor = Colors.green;
                      statusLabel = 'مكتملة ✅';
                    }

                    return Card(
                      color: AppTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(round, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(teamA, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                                  child: Text('$scoreA - $scoreB', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                ),
                                Expanded(
                                  child: Text(teamB, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('التوقيت: $time', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  tooltip: 'حذف المباراة',
                                  onPressed: () => _confirmDeleteMatch(context, matchId, '$teamA ضد $teamB'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.cardDark,
      onSelected: (_) => setState(() => _selectedStatus = value),
    );
  }
}
