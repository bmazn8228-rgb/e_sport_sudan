import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'organizer_referees_screen.dart';
import 'organizer_matches_screen.dart';
import 'organizer_complaints_screen.dart';
import 'organizer_teams_screen.dart';

import 'package:e_sport_sudan/features/admin/presentation/screens/tournament_admin_dashboard_screen.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';

class OrganizerDashboard extends StatefulWidget {
  OrganizerDashboard({super.key});

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2))),
          SizedBox(height: 16),
          Text('اختر البطولة النشطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getTournamentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                );
              }
              final tournaments = snapshot.data ?? [];
              if (tournaments.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد بطولات حالياً', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final t = tournaments[index];
                  final isActive = _activeTournament?['id'] == t['id'];
                  return ListTile(
                    leading: Icon(Icons.emoji_events, color: isActive ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                    title: Text(t['title'] ?? t['name'] ?? 'بطولة', style: TextStyle(color: isActive ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(t['game'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                    trailing: isActive ? Icon(Icons.check_circle, color: AppTheme.primaryBlue) : null,
                    onTap: () {
                      setState(() => _activeTournament = t);
                      Navigator.pop(ctx);
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleGenerateDraw() async {
    if (_activeTournament == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('تأكيد توليد القرعة'),
        content: Text('هل ترغب في توليد قرعة ومواجهات تلقائية لبطولة "${_activeTournament!['title'] ?? 'البطولة'}" وحفظها في قاعدة البيانات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('توليد القرعة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            content: Text('تم توليد وجدولة $count مواجهات في القرعة بنجاح في Firebase! 🎉', style: TextStyle(color: Colors.black)),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    Text('جدولة مباراة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 14),
                    Text('الفريق الأول (Team A):', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                    SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTeamA,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      hint: Text('اختر الفريق أ'),
                      items: teams.map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] ?? 'فريق'))).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedTeamA = val;
                          teamAName = teams.firstWhere((t) => t['id'] == val)['name'];
                        });
                      },
                    ),
                    SizedBox(height: 14),
                    Text('الفريق الثاني (Team B):', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                    SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTeamB,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      hint: Text('اختر الفريق ب'),
                      items: teams.where((t) => t['id'] != selectedTeamA).map((t) => DropdownMenuItem(value: t['id'] as String, child: Text(t['name'] ?? 'فريق'))).toList(),
                      onChanged: (val) {
                        setSheetState(() {
                          selectedTeamB = val;
                          teamBName = teams.firstWhere((t) => t['id'] == val)['name'];
                        });
                      },
                    ),
                    SizedBox(height: 14),
                    TextField(
                      controller: roundController,
                      decoration: InputDecoration(labelText: 'الدور / الجولة', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 14),
                    TextField(
                      controller: timeController,
                      decoration: InputDecoration(labelText: 'التوقيت والتاريخ', border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: EdgeInsets.symmetric(vertical: 14)),
                        onPressed: isSaving ? null : () async {
                          if (selectedTeamA == null || selectedTeamB == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('يرجى اختيار الفريقين أولاً'), backgroundColor: Colors.orange),
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
                              SnackBar(content: Text('تمت جدولة المباراة بنجاح في Firebase ✅', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue),
                            );
                          } catch (e) {
                            setSheetState(() => isSaving = false);
                            messenger.showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                          }
                        },
                        child: Text(isSaving ? 'جاري الجدولة...' : 'حفظ وجدولة المباراة 📅', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        SnackBar(content: Text('يرجى اختيار البطولة النشطة أولاً من الأعلى 👆'), backgroundColor: Colors.orange),
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
        title: Text('لوحة تحكم منظم البطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          IconButton(
            icon: Icon(Icons.emoji_events_outlined, color: Colors.amber),
            tooltip: 'إدارة وتعديل البطولات',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentAdminDashboardScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Tournament Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.emoji_events, color: AppTheme.primaryBlue, size: 28),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('البطولة النشطة', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                        Text(
                          _activeTournament != null
                              ? (_activeTournament!['title'] ?? _activeTournament!['name'] ?? 'بطولة')
                              : 'اختر بطولة...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _showTournamentPicker(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryBlue),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text('تبديل', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Tournament Management Direct Portal Card
            ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.withValues(alpha: 0.3))),
              leading: Icon(Icons.add_circle_outline, color: Colors.amber, size: 26),
              title: Text('إدارة البطولات وإضافة بطولة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('إنشاء بطولات جديدة، تعديل الحالات، وحذف البطولات', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
              trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.amber),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentAdminDashboardScreen()));
              },
            ),
            SizedBox(height: 20),

            // Bento Grid Stats
            Text('مؤشرات تقدم المنافسة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              children: [
                _buildStreamStatTile('الفرق المشاركة', FirestoreService().getAllTeamsStream(), Icons.groups, AppTheme.primaryBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerTeamsScreen()));
                }),
                SizedBox(width: 10),
                _buildStreamStatTile(
                  'المباريات المكتملة', 
                  FirestoreService().getAllMatchesStream(), 
                  Icons.sports_score, 
                  Colors.orange, 
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerMatchesScreen()));
                  },
                  filter: (m) => m['status'] == 'completed',
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                _buildStreamStatTile('حكام الساحة النشطين', FirestoreService().getUsersByRoleStream('referee'), Icons.sports, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerRefereesScreen()));
                }),
                SizedBox(width: 10),
                _buildStreamStatTile('الاعتراضات والشكاوى', FirestoreService().getComplaintsStream(), Icons.warning_amber, Colors.red, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerComplaintsScreen()));
                }),
              ],
            ),
            SizedBox(height: 24),

            // TME Engine Actions
            Text('أدوات محرك البطولات (TME Controls)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingDraw ? null : _handleGenerateDraw,
                      icon: _isGeneratingDraw
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Icon(Icons.auto_awesome, color: Colors.black),
                      label: Text(_isGeneratingDraw ? 'جاري توليد القرعة...' : 'توليد القرعة التلقائية وتوزيع المجموعات 🎲', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showScheduleMatchDialog,
                          icon: Icon(Icons.schedule, size: 18, color: Theme.of(context).colorScheme.onSurface),
                          label: Text('جدولة المباريات 📅', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)), padding: EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isApproving ? null : _handleApproveResults,
                          icon: Icon(Icons.verified, size: 18, color: AppTheme.primaryBlue),
                          label: Text(_isApproving ? 'جاري الاعتماد...' : 'اعتماد النتائج والنقاط 🏆', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.primaryBlue), padding: EdgeInsets.symmetric(vertical: 12)),
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
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)))),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
