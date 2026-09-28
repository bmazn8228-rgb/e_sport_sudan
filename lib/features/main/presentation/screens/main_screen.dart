import 'package:flutter/material.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/player_search_screen.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_search_screen.dart';
import 'package:e_sport_sudan/features/main/presentation/screens/news_screen.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
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
import 'package:e_sport_sudan/features/profile/presentation/screens/notifications_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  final bool isGuest;
  const MainScreen({super.key, this.isGuest = false});

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
        NotificationService().initialize();
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
      LiveMatchScreen(matchId: 'sample_live_match'),
      RankingsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_currentIndex],
      bottomNavigationBar: _buildFloatingGlassNavBar(),
    );
  }

  Widget _buildFloatingGlassNavBar() {
    final navItems = [
      {'icon': Icons.sports_esports_rounded, 'label': 'الرئيسية'},
      {'icon': Icons.emoji_events_rounded, 'label': 'البطولات'},
      {'icon': Icons.live_tv_rounded, 'label': 'المباريات'},
      {'icon': Icons.leaderboard_rounded, 'label': 'التصنيف'},
      {'icon': Icons.person_rounded, 'label': 'حسابي'},
    ];

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 20),
      height: 68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xE6121722) : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(navItems.length, (index) {
                final isSelected = _currentIndex == index;
                final item = navItems[index];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _currentIndex = index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 14 : 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.35,
                              ),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                          size: 22,
                        ),
                        SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final bool isGuest;
  final Function(int)? onNavigateTab;
  const HomeScreen({super.key, this.isGuest = false, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                ),
                image: DecorationImage(
                  image: AssetImage('assets/images/app_logo.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، ${FirebaseAuth.instance.currentUser?.displayName ?? 'يا كابتن'} 👋',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'جاهز لمنافسات اليوم؟',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Notification Bell (iOS Style)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // iOS Style Search Bar
            HomeSearchBar(),
            SizedBox(height: 20),

            // Featured Tournament Banner
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getTournamentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryBlue,
                    ),
                  );
                }

                final tournaments = snapshot.data ?? [];
                if (tournaments.isEmpty) {
                  return SizedBox();
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
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryBlue.withValues(alpha: 0.1), AppTheme.primaryRed.withValues(alpha: 0.1)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                        image: (posterUrl != null && posterUrl.isNotEmpty)
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(posterUrl),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.45),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'أحدث بطولة',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '🏆 $prize',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            right: 16,
                            left: 16,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (logoUrl != null && logoUrl.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: logoUrl,
                                        height: 52,
                                        width: 52,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          game,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    if (!isGuest)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TournamentRegistrationScreen(
                                      tournamentData: featured,
                                    ),
                              ),
                            );
                          },
                          icon: Icon(Icons.flag_rounded),
                          label: Text(
                            'عرض تفاصيل البطولة والتسجيل',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Quick Actions
            SizedBox(height: 20),
            _buildQuickActions(context),
            SizedBox(height: 24),

            // My Upcoming Matches
            _buildSectionHeader(
              'مبارياتي القادمة',
              Icons.timer,
              AppTheme.primaryBlue,
            ),
            SizedBox(height: 12),
            _buildUpcomingMatchCard(context),
            SizedBox(height: 24),

            // Live Matches Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  'مباريات حية ومباشرة',
                  Icons.circle,
                  Colors.red,
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
            SizedBox(height: 10),

            // Live Match Card
            _buildLiveMatchCard(context),
            SizedBox(height: 24),

            // Top 3 Leaderboard
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  'صدارة الترتيب الوطني',
                  Icons.leaderboard,
                  Colors.amber,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Rankings Tab
                  },
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildTopLeaderboard(context),
            SizedBox(height: 24),

            // Recent News
            _buildSectionHeader(
              'آخر الأخبار والمقالات',
              Icons.article,
              Colors.blue,
            ),
            SizedBox(height: 12),
            _buildNewsSection(context),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(
          context,
          'البطولات',
          Icons.emoji_events,
          Colors.amber,
          () {
            if (onNavigateTab != null) onNavigateTab!(1);
          },
        ),
        _buildActionItem(
          context,
          'فريق جديد',
          Icons.group_add,
          AppTheme.primaryBlue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamManagementScreen(),
              ),
            );
          },
        ),
        _buildActionItem(
          context,
          'التصنيف',
          Icons.bar_chart,
          Colors.purpleAccent,
          () {
            if (onNavigateTab != null) onNavigateTab!(3);
          },
        ),
        _buildActionItem(
          context,
          'المحفظة',
          Icons.account_balance_wallet,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WalletScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatchCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لا توجد مباريات مجدولة اليوم',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  'ستظهر مباريات فريقك القادمة فور إعلان جدول التصفيات.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
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
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          );
        }

        final data = snapshot.data?.data();
        final isLive =
            (data != null &&
            data['isLive'] == true &&
            (data['youtubeVideoId'] ?? '').toString().isNotEmpty);

        if (!isLive) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.tv_off_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لا يوجد بث مباشر نشط حالياً',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'سيظهر البث هنا فور قيام إدارة البطولة بنقل مجريات المباريات.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final title = data['title'] ?? 'مباراة مباشرة';

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark ? const [Color(0xFF261217), Color(0xFF131822)] : [Colors.red.shade50, Colors.blue.shade50],
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
                offset: Offset(0, 6),
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
                    padding: EdgeInsets.symmetric(
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
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Theme.of(context).colorScheme.onSurface, size: 7),
                        SizedBox(width: 5),
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
                    padding: EdgeInsets.symmetric(
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
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        SizedBox(width: 4),
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
              SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'البث المباشر الرسمي المعتمد من الاتحاد السوداني للرياضات الإلكترونية',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), fontSize: 12),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LiveMatchScreen(matchId: 'sample_live_match'),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  label: Text(
                    'مشاهدة البث والدردشة الحية الآن',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopLeaderboard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.leaderboard_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المتصدرون في الموسم الأول',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 3),
                Text(
                  'شاهد أداء نخبة اللاعبين والفرق في السودان.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (onNavigateTab != null) onNavigateTab!(3);
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'عرض',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NewsListScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.newspaper_rounded,
                color: Colors.blueAccent,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أخبار وبلاغات الاتحاد',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'إعلانات فتح باب التسجيل وتحديثات القوانين التحكيمية.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({Key? key}) : super(key: key);
  @override
  _HomeSearchBarState createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  String _searchType = 'team'; // 'team' or 'player'
  final TextEditingController _controller = TextEditingController();

  void _showSearchOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.all(20),
              height: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حدد نوع البحث', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  RadioListTile<String>(
                    title: Text('بحث عن فريق 🛡️'),
                    value: 'team',
                    groupValue: _searchType,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      setState(() => _searchType = val!);
                      setStateSheet(() => _searchType = val!);
                      Navigator.pop(ctx);
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('بحث عن لاعب 🎮'),
                    value: 'player',
                    groupValue: _searchType,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      setState(() => _searchType = val!);
                      setStateSheet(() => _searchType = val!);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    
    if (_searchType == 'player') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerSearchScreen(initialQuery: query.trim())));
    } else if (_searchType == 'team') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TeamSearchScreen(initialQuery: query.trim())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: _controller,
        onSubmitted: _executeSearch,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: _searchType == 'team' ? 'ابحث عن فريق...' : 'ابحث عن لاعب...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 14,
          ),
          prefixIcon: IconButton(
            icon: Icon(Icons.search_rounded),
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            iconSize: 22,
            onPressed: () => _executeSearch(_controller.text),
          ),
          suffixIcon: GestureDetector(
            onTap: _showSearchOptions,
            child: Container(
              margin: EdgeInsets.all(6),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: AppTheme.primaryBlue,
                size: 18,
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
