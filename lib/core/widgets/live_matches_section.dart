import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/tournament/presentation/screens/bracket_screen.dart';
import 'package:e_sport_sudan/features/match/presentation/screens/live_match_screen.dart';

class LiveMatchesSection extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const LiveMatchesSection({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService().getActiveLiveMatchStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildEmptyOfflineState(context);
        }

        final data = snapshot.data!;
        final title = data['title'] ?? 'مباراة مباشرة';
        final matchId = data['id'] ?? 'sample_live_match';
        final teamA = data['teamA'] as String?;
        final teamB = data['teamB'] as String?;
        final scoreA = data['scoreA'];
        final scoreB = data['scoreB'];

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.3, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, val, child) {
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.8 * val),
                                blurRadius: 8 * val,
                                spreadRadius: 3 * val,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'مباريات حية ومباشرة',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BracketScreen(
                          tournamentTitle: 'بطولة السودان الكبرى 2025',
                          tournamentId: '',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'شجرة المباريات',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? const [Color(0xFF261217), Color(0xFF131822)]
                      : [Colors.red.shade50, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Theme.of(context).colorScheme.onSurface, size: 7),
                            const SizedBox(width: 5),
                            Text(
                              'مباشر الآن',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.redAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'YouTube Live',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'البث المباشر الرسمي المعتمد من الاتحاد السوداني للرياضات الإلكترونية',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), fontSize: 12),
                  ),
                  if (teamA != null && teamB != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              teamA,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '${scoreA ?? 0} : ${scoreB ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              teamB,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (onNavigateTab != null) {
                          onNavigateTab!(2);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveMatchScreen(matchId: matchId),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                      label: const Text(
                        'مشاهدة البث والدردشة الحية الآن',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
  Widget _buildEmptyOfflineState(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.sensors_off_rounded, color: Colors.grey, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'مباريات حية ومباشرة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.live_tv_rounded, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text(
                'لا توجد مباريات مباشرة حالياً',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم عرض المباريات والبطولات فور بدء البث المباشر المعتمد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
