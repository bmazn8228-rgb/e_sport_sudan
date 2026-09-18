import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/tournament_admin_dashboard_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/match/presentation/screens/live_match_screen.dart';
import 'package:e_sport_sudan/features/tournament/presentation/screens/tournaments_screen.dart';
import 'package:e_sport_sudan/features/tournament/presentation/screens/bracket_screen.dart';
import 'package:e_sport_sudan/features/tournament/presentation/screens/tournament_registration_screen.dart';
import 'package:e_sport_sudan/features/rankings/presentation/screens/rankings_screen.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/profile_screen.dart';
import 'package:e_sport_sudan/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_management_screen.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  final bool isGuest;
  const MainScreen({Key? key, this.isGuest = false}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isGuest) {
        NotificationService().initialize(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        isGuest: widget.isGuest,
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      TournamentsScreen(isGuest: widget.isGuest),
      const LiveMatchScreen(matchId: 'sample_live_match'),
      const RankingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.backgroundDark,
        selectedItemColor: AppTheme.primaryGreen,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'البطولات'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_kabaddi), label: 'المباريات'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'التصنيف'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final bool isGuest;
  final Function(int)? onNavigateTab;
  const HomeScreen({Key? key, this.isGuest = false, this.onNavigateTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              child: const Icon(Icons.person, color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مساء الخير 👋 يا كابتن أحمد', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('جاهز لمنافسات اليوم في الدوري القومي؟', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('4G • متزامن', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن بطولة، فريق، لاعب أو لعبة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.tune),
                filled: true,
                fillColor: AppTheme.cardDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 20),

            // Featured Tournament Banner
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getTournamentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
                }
                
                final tournaments = snapshot.data ?? [];
                if (tournaments.isEmpty) {
                  return const SizedBox();
                }

                final featured = tournaments.first;
                final posterUrl = featured['posterUrl'] as String?;
                final logoUrl = featured['logoUrl'] as String?;
                final title = featured['title'] ?? 'بطولة كبرى';
                final prize = featured['prizePool'] ?? '0';
                final game = featured['game'] ?? 'E-Sports';

                return Column(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D2818), Color(0xFF040F08)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                        image: (posterUrl != null && posterUrl.isNotEmpty) 
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(posterUrl),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                            )
                          : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('أحدث بطولة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('🏆 $prize', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 16,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (logoUrl != null && logoUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Chip(label: Text(game, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                                    const SizedBox(height: 4),
                                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!isGuest)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TournamentRegistrationScreen(tournamentTitle: title),
                            ),
                          );
                        },
                        icon: const Icon(Icons.flag),
                        label: const Text('عرض البطولة والتسجيل'),
                      ),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),

            // Quick Actions
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 24),

            // My Upcoming Matches
            _buildSectionHeader('مبارياتي القادمة', Icons.timer, AppTheme.primaryGreen),
            const SizedBox(height: 12),
            _buildUpcomingMatchCard(),
            const SizedBox(height: 24),

            // Live Matches Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('مباريات حية ومباشرة', Icons.circle, Colors.red),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BracketScreen(tournamentTitle: 'بطولة السودان الكبرى 2025'),
                      ),
                    );
                  },
                  child: const Text('شجرة المباريات', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Live Match Card
            _buildLiveMatchCard(context),
            const SizedBox(height: 24),

            // Top 3 Leaderboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('صدارة الترتيب الوطني', Icons.leaderboard, Colors.amber),
                TextButton(
                  onPressed: () {
                    // Navigate to Rankings Tab
                  },
                  child: const Text('عرض الكل', style: TextStyle(color: AppTheme.primaryGreen, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTopLeaderboard(),
            const SizedBox(height: 24),

            // Recent News
            _buildSectionHeader('آخر الأخبار والمقالات', Icons.article, Colors.blue),
            const SizedBox(height: 12),
            _buildNewsSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(context, 'البطولات', Icons.emoji_events, Colors.amber, () {
          if (onNavigateTab != null) onNavigateTab!(1);
        }),
        _buildActionItem(context, 'فريق جديد', Icons.group_add, AppTheme.primaryGreen, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamManagementScreen()));
        }),
        _buildActionItem(context, 'التصنيف', Icons.bar_chart, Colors.purpleAccent, () {
          if (onNavigateTab != null) onNavigateTab!(3);
        }),
        _buildActionItem(context, 'المحفظة', Icons.account_balance_wallet, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen()));
        }),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_esports, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('صقور النيل vs الذئاب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('نصف نهائي ببجي موبايل', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('اليوم 8:00 م', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
              Text('تبدأ بعد 3 ساعات', style: TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMatchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.remove_red_eye, color: Colors.white54, size: 14),
                  SizedBox(width: 4),
                  Text('1.4K مشاهد', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
              const Text('دقيقة 78\'', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text('مباشر LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTeamColumn('صقور النيل', 'Nile Falcons', Icons.sports_kabaddi),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                child: const Text('2 : 1', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
              _buildTeamColumn('فرسان المقرن', 'Mogran Knights', Icons.security),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LiveMatchScreen(matchId: 'sample_live_match')),
              );
            },
            icon: const Icon(Icons.play_arrow, color: AppTheme.primaryGreen),
            label: const Text('دخول البث المباشر والتصويت', style: TextStyle(color: AppTheme.primaryGreen)),
          )
        ],
      ),
    );
  }

  Widget _buildTopLeaderboard() {
    return Row(
      children: [
        Expanded(child: _buildLeaderboardCard('2', 'أبطال مدني', '1,350', Colors.grey[400]!)),
        const SizedBox(width: 8),
        Expanded(child: _buildLeaderboardCard('1', 'صقور النيل', '1,420', Colors.amber)),
        const SizedBox(width: 8),
        Expanded(child: _buildLeaderboardCard('3', 'ذئاب بورتسودان', '1,280', Colors.brown[300]!)),
      ],
    );
  }

  Widget _buildLeaderboardCard(String rank, String name, String points, Color rankColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: rankColor.withOpacity(0.2),
            radius: 16,
            child: Text(rank, style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('$points MMR', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildNewsCard('تحديث فالورانت الجديد يعيد تشكيل خارطة الميتا!', 'تحليل تكتيكي', Colors.purple),
          const SizedBox(width: 12),
          _buildNewsCard('مقابلة حصرية مع بطل السودان للعبة EA FC 25', 'لقاءات حصرية', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String title, String category, Color categoryColor) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: const NetworkImage('https://via.placeholder.com/240x140/1E293B/FFFFFF?text=News'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: categoryColor, borderRadius: BorderRadius.circular(4)),
            child: Text(category, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(String nameAr, String nameEn, IconData icon) {
    return Column(
      children: [
        CircleAvatar(radius: 22, backgroundColor: Colors.white12, child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(height: 6),
        Text(nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(nameEn, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
