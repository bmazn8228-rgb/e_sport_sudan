import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizerTeamsScreen extends StatefulWidget {
  const OrganizerTeamsScreen({super.key});

  @override
  State<OrganizerTeamsScreen> createState() => _OrganizerTeamsScreenState();
}

class _OrganizerTeamsScreenState extends State<OrganizerTeamsScreen> {
  String _selectedGame = 'all';

  void _showAddTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final leaderController = TextEditingController();
    String selectedGame = 'PUBG Mobile';
    final games = ['PUBG Mobile', 'EA FC 25', 'Free Fire', 'Valorant'];
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
              const Text('إضافة وتسجيل فريق جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الفريق', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: leaderController,
                decoration: const InputDecoration(labelText: 'اسم قائد الفريق (الكابتن)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedGame,
                dropdownColor: AppTheme.cardDark,
                decoration: const InputDecoration(labelText: 'اللعبة', border: OutlineInputBorder()),
                items: games.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setSheetState(() => selectedGame = val!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: isSaving ? null : () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال اسم الفريق'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    setSheetState(() => isSaving = true);
                    try {
                      await FirestoreService().registerTeam({
                        'name': nameController.text.trim(),
                        'leaderName': leaderController.text.trim().isEmpty ? 'كابتن الفريق' : leaderController.text.trim(),
                        'game': selectedGame,
                        'points': 0,
                        'wins': 0,
                        'losses': 0,
                        'membersCount': 1,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت إضافة الفريق بنجاح ✅', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue),
                        );
                      }
                    } catch (e) {
                      setSheetState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                      }
                    }
                  },
                  child: Text(isSaving ? 'جاري الحفظ...' : 'تسجيل الفريق 🛡️', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTeam(BuildContext context, String? id, String name) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من رغبتك في حذف فريق "$name"؟', style: const TextStyle(color: Colors.white70)),
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
                await FirestoreService().deleteTeam(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الفريق بنجاح ✅', style: TextStyle(color: Colors.black)),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فشل في حذف الفريق ❌', style: TextStyle(color: Colors.white)),
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
        title: const Text('الفرق المشاركة والمعتمدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTeamDialog(context),
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
                _buildFilterChip('all', 'جميع الألعاب'),
                const SizedBox(width: 8),
                _buildFilterChip('PUBG Mobile', 'PUBG Mobile'),
                const SizedBox(width: 8),
                _buildFilterChip('EA FC 25', 'EA FC 25'),
                const SizedBox(width: 8),
                _buildFilterChip('Free Fire', 'Free Fire'),
                const SizedBox(width: 8),
                _buildFilterChip('Valorant', 'Valorant'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getAllTeamsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                var teams = snapshot.data ?? [];
                if (_selectedGame != 'all') {
                  teams = teams.where((t) => t['game'] == _selectedGame).toList();
                }

                if (teams.isEmpty) {
                  return const Center(child: Text('لا توجد فرق مطابقة للعبة المحددة', style: TextStyle(color: Colors.white54, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return Card(
                      color: AppTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryBlue,
                          child: Icon(Icons.shield, color: Colors.black),
                        ),
                        title: Text(team['name'] ?? 'فريق مجهول', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('اللعبة: ${team['game'] ?? 'غير محدد'}\nالنقاط: ${team['points'] ?? 0} • الانتصارات: ${team['wins'] ?? 0}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'حذف الفريق',
                          onPressed: () => _confirmDeleteTeam(context, team['id'], team['name'] ?? 'الفريق'),
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
    final isSelected = _selectedGame == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.cardDark,
      onSelected: (_) => setState(() => _selectedGame = value),
    );
  }
}
