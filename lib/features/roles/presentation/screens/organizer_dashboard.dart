import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'organizer_referees_screen.dart';
import 'organizer_matches_screen.dart';
import 'organizer_complaints_screen.dart';
import 'organizer_teams_screen.dart';

import 'package:e_sport_sudan/features/admin/presentation/screens/tournament_admin_dashboard_screen.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  Map<String, dynamic>? _activeTournament;
  bool _isGeneratingDraw = false;
  bool _isApproving = false;

  void _showTournamentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('اختر البطولة النشطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getTournamentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                );
              }
              final tournaments = snapshot.data ?? [];
              if (tournaments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد بطولات حالياً', style: TextStyle(color: Colors.white54)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final t = tournaments[index];
                  final isActive = _activeTournament?['id'] == t['id'];
                  return ListTile(
                    leading: Icon(Icons.emoji_events, color: isActive ? AppTheme.primaryBlue : Colors.white54),
                    title: Text(t['title'] ?? t['name'] ?? 'بطولة', style: TextStyle(color: isActive ? AppTheme.primaryBlue : Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(t['game'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: isActive ? const Icon(Icons.check_circle, color: AppTheme.primaryBlue) : null,
                    onTap: () {
                      setState(() => _activeTournament = t);
                      Navigator.pop(ctx);
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleGenerateDraw() async {
    if (_activeTournament == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار البطولة النشطة أولاً من الأعلى 👆'),
          backgroundColor: Colors.orange,
        ),
      );
      _showTournamentPicker(context);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('تأكيد توليد القرعة'),
        content: Text('هل ترغب في توليد قرعة ومواجهات تلقائية لبطولة "${_activeTournament!['title'] ?? 'البطولة'}" وحفظها في قاعدة البيانات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('توليد القرعة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGeneratingDraw = true);
    try {
      final count = await FirestoreService().autoGenerateTournamentDraw(
        tournamentId: _activeTournament!['id'],
        tournamentName: _activeTournament!['title'] ?? 'بطولة',
        game: _activeTournament!['game'] ?? 'PUBG Mobile',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم توليد وجدولة $count مواجهات في القرعة بنجاح في Firebase! 🎉', style: const TextStyle(color: Colors.black)),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تنبيه: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingDraw = false);
    }
  }

  void _showScheduleMatchDialog() {
    final roundController = TextEditingController(text: 'دور المجموعات');
    final timeController = TextEditingController(text: 'اليوم 19:00');
    String? selectedTeamA;
    String? selectedTeamB;
    String? teamAName;
    String? teamBName;
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getAllTeamsStream(),
            builder: (ctx, snapshot) {
              final teams = snapshot.data ?? [];
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('جدولة مباراة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    const Text('الفريق الأول (Team A):', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTeamA,
                      dropdownColor: AppTheme.cardDark,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('اختر الفريق أ'),
                      items: teams.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] ?? 'فريق'))).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedTeamA = val;
                          teamAName = teams.firstWhere((t) => t['id'] == val)['name'];
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('الفريق الثاني (Team B):', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTeamB,
                      dropdownColor: AppTheme.cardDark,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('اختر الفريق ب'),
                      items: teams.where((t) => t['id'] != selectedTeamA).map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] ?? 'فريق'))).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedTeamB = val;
                          teamBName = teams.firstWhere((t) => t['id'] == val)['name'];
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: roundController,
                      decoration: const InputDecoration(labelText: 'الدور / الجولة', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(labelText: 'التوقيت والتاريخ', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: isSaving ? null : () async {
                          if (selectedTeamA == null || selectedTeamB == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يرجى اختيار الفريقين أولاً'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          setSheetState(() => isSaving = true);
                          try {
                            await FirestoreService().createMatch({
                              'tournamentId': _activeTournament?['id'] ?? 'general',
                              'tournamentName': _activeTournament?['title'] ?? 'مباراة ودية / عامة',
                              'game': _activeTournament?['game'] ?? 'عام',
                              'teamA': teamAName ?? 'الفريق أ',
                              'teamAId': selectedTeamA,
                              'teamB': teamBName ?? 'الفريق ب',
                              'teamBId': selectedTeamB,
                              'scoreA': 0,
                              'scoreB': 0,
                              'status': 'scheduled',
                              'time': timeController.text.trim(),
                              'round': roundController.text.trim(),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('تمت جدولة المباراة بنجاح في Firebase ✅', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue),
                            );
                          } catch (e) {
                            setSheetState(() => isSaving = false);
                            messenger.showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                          }
                        },
                        child: Text(isSaving ? 'جاري الجدولة...' : 'حفظ وجدولة المباراة 📅', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleApproveResults() async {
    if (_activeTournament == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار البطولة النشطة أولاً من الأعلى 👆'), backgroundColor: Colors.orange),
      );
      _showTournamentPicker(context);
      return;
    }

    setState(() => _isApproving = true);
    try {
      final updated = await FirestoreService().approveTournamentResults(_activeTournament!['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updated > 0 ? 'تم اعتماد نتائج $updated مباراة واحتساب النقاط تلقائياً! 🏆' : 'لا توجد مباريات مكتملة بانتظار الاعتماد حالياً'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة تحكم منظم البطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
            tooltip: 'إدارة وتعديل البطولات',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TournamentAdminDashboardScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Tournament Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.emoji_events, color: AppTheme.primaryBlue, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('البطولة النشطة', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        Text(
                          _activeTournament != null
                              ? (_activeTournament!['title'] ?? _activeTournament!['name'] ?? 'بطولة')
                              : 'اختر بطولة...',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showTournamentPicker(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('تبديل', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tournament Management Direct Portal Card
            ListTile(
              tileColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.withValues(alpha: 0.3))),
              leading: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 26),
              title: const Text('إدارة البطولات وإضافة بطولة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('إنشاء بطولات جديدة، تعديل الحالات، وحذف البطولات', style: TextStyle(fontSize: 11, color: Colors.white54)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.amber),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TournamentAdminDashboardScreen()));
              },
            ),
            const SizedBox(height: 20),

            // Bento Grid Stats
            const Text('مؤشرات تقدم المنافسة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStreamStatTile('الفرق المشاركة', FirestoreService().getAllTeamsStream(), Icons.groups, AppTheme.primaryBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerTeamsScreen()));
                }),
                const SizedBox(width: 10),
                _buildStreamStatTile(
                  'المباريات المكتملة', 
                  FirestoreService().getAllMatchesStream(), 
                  Icons.sports_score, 
                  Colors.orange, 
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerMatchesScreen()));
                  },
                  filter: (m) => m['status'] == 'completed',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStreamStatTile('حكام الساحة النشطين', FirestoreService().getUsersByRoleStream('referee'), Icons.sports, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerRefereesScreen()));
                }),
                const SizedBox(width: 10),
                _buildStreamStatTile('الاعتراضات والشكاوى', FirestoreService().getComplaintsStream(), Icons.warning_amber, Colors.red, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerComplaintsScreen()));
                }),
              ],
            ),
            const SizedBox(height: 24),

            // TME Engine Actions
            const Text('أدوات محرك البطولات (TME Controls)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingDraw ? null : _handleGenerateDraw,
                      icon: _isGeneratingDraw
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.auto_awesome, color: Colors.black),
                      label: Text(_isGeneratingDraw ? 'جاري توليد القرعة...' : 'توليد القرعة التلقائية وتوزيع المجموعات 🎲', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showScheduleMatchDialog,
                          icon: const Icon(Icons.schedule, size: 18, color: Colors.white),
                          label: const Text('جدولة المباريات 📅', style: TextStyle(color: Colors.white, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isApproving ? null : _handleApproveResults,
                          icon: const Icon(Icons.verified, size: 18, color: AppTheme.primaryBlue),
                          label: Text(_isApproving ? 'جاري الاعتماد...' : 'اعتماد النتائج والنقاط 🏆', style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryBlue), padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamStatTile(String label, Stream<List<dynamic>> stream, IconData icon, Color color, VoidCallback onTap, {bool Function(dynamic)? filter}) {
    return StreamBuilder<List<dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        String countStr = '0';
        if (snapshot.hasData) {
          final list = snapshot.data!;
          final count = filter != null ? list.where(filter).length : list.length;
          countStr = count.toString();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          countStr = '...';
        }
        return _buildStatTile(label, countStr, icon, color, onTap);
      },
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54))),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
