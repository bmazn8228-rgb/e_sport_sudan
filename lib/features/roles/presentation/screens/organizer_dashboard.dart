import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'organizer_referees_screen.dart';
import 'organizer_matches_screen.dart';
import 'organizer_complaints_screen.dart';
import 'organizer_teams_screen.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  Map<String, dynamic>? _activeTournament;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة تحكم منظم البطولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: const Text('صلاحية منظم', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.orange,
                          content: Text('قريباً: سيتم إضافة خوارزمية التوزيع التلقائي في التحديث القادم!', style: TextStyle(color: Colors.black)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('توليد القرعة التلقائية وتوزيع المجموعات'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ميزة الجدولة تحت التطوير 🚧'), backgroundColor: Colors.orange),
                            );
                          },
                          icon: const Icon(Icons.schedule, size: 18, color: Colors.white),
                          label: const Text('جدولة المباريات', style: TextStyle(color: Colors.white, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ميزة الاعتماد المجمع قيد التطوير 🚧'), backgroundColor: Colors.orange),
                            );
                          },
                          icon: const Icon(Icons.verified, size: 18, color: AppTheme.primaryBlue),
                          label: const Text('اعتماد النتائج', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryBlue)),
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
