import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'tournament_registration_screen.dart';

class TournamentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> tournament;
  const TournamentDetailsScreen({super.key, required this.tournament});

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'open': return AppTheme.primaryBlue;
      case 'ongoing': return Colors.orange;
      case 'completed': return Colors.white38;
      default: return Colors.white54;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'open': return 'مفتوح للتسجيل';
      case 'ongoing': return 'جارية الآن';
      case 'completed': return 'منتهية';
      default: return 'قريباً';
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = tournament['id'] ?? '';
    final title = tournament['title'] ?? tournament['name'] ?? 'بطولة';
    final game = tournament['game'] ?? '';
    final prize = tournament['prizePool'] ?? tournament['prize'] ?? '';
    final fee = tournament['registrationFee'] ?? tournament['entryFee'] ?? '';
    final status = tournament['status'] ?? 'open';
    final description = tournament['description'] ?? 'لا يوجد وصف متاح.';
    final imageUrl = tournament['imageUrl'] ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderHeader(title))
                  : _buildPlaceholderHeader(title),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Game Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.4)),
                        ),
                        child: Text(_getStatusText(status), style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Icon(Icons.sports_esports, color: Colors.white54, size: 14),
                          const SizedBox(width: 6),
                          Text(game, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Cards Row
                  Row(
                    children: [
                      _infoCard(Icons.emoji_events, 'الجائزة', prize.toString().isNotEmpty ? '$prize ج.س' : 'غير محدد', Colors.amber),
                      const SizedBox(width: 10),
                      _infoCard(Icons.account_balance_wallet, 'رسوم التسجيل', fee.toString().isNotEmpty ? '$fee ج.س' : 'مجاني', AppTheme.primaryBlue),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('عن البطولة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12)),
                    child: Text(description, style: const TextStyle(color: Colors.white70, height: 1.6)),
                  ),
                  const SizedBox(height: 24),

                  // Registered Teams
                  const Text('الفرق المسجلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (id.isNotEmpty)
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FirestoreService().getTournamentRegistrationsStream(id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                        }
                        final regs = snapshot.data ?? [];
                        if (regs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Text('لم يتسجل أحد بعد. كن الأول!', style: TextStyle(color: Colors.white54))),
                          );
                        }
                        return Column(
                          children: regs.take(5).map((reg) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                              child: Text(reg['teamName']?.toString().substring(0, 1) ?? '؟',
                                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(reg['teamName'] ?? 'فريق', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('الكابتن: ${reg['leaderName'] ?? 'غير معروف'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 16),
                          )).toList(),
                        );
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: status == 'open'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => TournamentRegistrationScreen(tournamentData: tournament))),
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('سجل فريقك الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPlaceholderHeader(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryRed.withValues(alpha: 0.1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(child: Icon(Icons.emoji_events, size: 80, color: Colors.white24)),
    );
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          )),
        ]),
      ),
    );
  }
}
