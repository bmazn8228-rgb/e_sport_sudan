import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'organizer_referees_screen.dart';
import 'organizer_matches_screen.dart';
import 'organizer_complaints_screen.dart';
import 'organizer_teams_screen.dart';

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({Key? key}) : super(key: key);

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
              color: Colors.orange.withOpacity(0.2),
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
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.emoji_events, color: AppTheme.primaryGreen, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('النطاق والتحكم الميداني', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        Text('كأس السودان الكبرى 2025', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('تبديل', style: TextStyle(color: Colors.white, fontSize: 11)),
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
                _buildStreamStatTile('الفرق المشاركة', FirestoreService().getAllTeamsStream(), Icons.groups, AppTheme.primaryGreen, () {
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
                          backgroundColor: AppTheme.primaryGreen,
                          content: Text('تم تشغيل محرك TME وتوليد القرعة تلقائياً للأدوار الإقصائية!', style: TextStyle(color: Colors.black)),
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
                          onPressed: () {},
                          icon: const Icon(Icons.schedule, size: 18, color: Colors.white),
                          label: const Text('جدولة المباريات', style: TextStyle(color: Colors.white, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.verified, size: 18, color: AppTheme.primaryGreen),
                          label: const Text('اعتماد النتائج', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryGreen)),
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
