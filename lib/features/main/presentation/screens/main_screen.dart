import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/tournament_admin_dashboard_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:firebase_auth/firebase_auth.dart';

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحباً بك 👋 ${FirebaseAuth.instance.currentUser?.displayName ?? 'يا كابتن'}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Text('جاهز لمنافسات اليوم في الدوري القومي؟', style: TextStyle(fontSize: 11, color: Colors.white70)),
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
                              builder: (context) => TournamentRegistrationScreen(tournamentData: featured),
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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text('يتوفر قريباً', style: TextStyle(color: Colors.white54, fontSize: 14)),
      ),
    );
  }

  Widget _buildLiveMatchCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getGlobalLiveStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          );
        }

        final data = snapshot.data?.data();
        final isLive = (data != null && data['isLive'] == true && (data['youtubeVideoId'] ?? '').toString().isNotEmpty);

        if (!isLive) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              children: [
                Icon(Icons.tv_off, color: Colors.white38, size: 36),
                SizedBox(height: 8),
                Text('لا يوجد بث مباشر نشط حالياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text('سيظهر البث هنا فور قيام إدارة البطولة بنقل المباريات', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          );
        }

        final title = data['title'] ?? 'مباراة مباشرة';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.6)),
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.15),
                AppTheme.cardDark,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text('مباشر الآن', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Text('YouTube Live 🔴', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'البث المباشر الرسمي المعتمد من اتحاد الرياضات الإلكترونية',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveMatchScreen(matchId: 'sample_live_match'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_fill, color: Colors.black),
                  label: const Text('مشاهدة البث والدردشة الحية الآن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopLeaderboard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text('يتوفر قريباً', style: TextStyle(color: Colors.white54, fontSize: 14)),
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text('يتوفر قريباً', style: TextStyle(color: Colors.white54, fontSize: 14)),
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
