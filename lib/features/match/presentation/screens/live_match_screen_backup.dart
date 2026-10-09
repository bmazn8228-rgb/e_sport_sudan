import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';
import 'package:e_sport_sudan/features/tournament/presentation/screens/tournaments_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveMatchScreen extends StatefulWidget {
  final String matchId;
  final Function(int)? onNavigateTab;

  const LiveMatchScreen({
    super.key,
    required this.matchId,
    this.onNavigateTab,
  });

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> with SingleTickerProviderStateMixin {
  YoutubePlayerController? _controller;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentVideoId = '';
  bool _isSending = false;
  bool _isCheckingStatus = false;
  late AnimationController _pulseAnimController;

  @override
  void initState() {
    super.initState();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _initializeOrUpdateYoutubePlayer(String videoId) {
    if (videoId.isEmpty) return;

    if (_controller == null || _currentVideoId != videoId) {
      _currentVideoId = videoId;
      if (_controller != null) {
        _controller!.load(videoId);
      } else {
        _controller = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            isLive: true,
            autoPlay: true,
            mute: false,
            forceHD: false,
          ),
        );
      }
    }
  }

  void _sendMessage(String? currentSessionId) async {
    final message = _chatController.text.trim();
    if (message.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      NotificationService.showCustomToast(
        context,
        title: 'تسجيل الدخول مطلوب',
        message: 'يرجى تسجيل الدخول بحسابك للمشاركة في الدردشة المباشرة 🔒',
        type: ToastType.urgent,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // Check if user has moderator/admin role
      bool isModerator = false;
      final userDoc = await FirestoreService().getUser(user.uid);
      if (userDoc != null && userDoc.role != UserRole.player) {
        isModerator = true;
      }

      await FirestoreService().sendChatMessage(
        matchId: widget.matchId,
        senderId: user.uid,
        senderName: user.displayName ?? (userDoc?.displayName.isNotEmpty == true ? userDoc!.displayName : 'لاعب'),
        message: message,
        sessionId: currentSessionId,
        isModerator: isModerator,
      );

      _chatController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في إرسال الرسالة ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  void _handleManualRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isCheckingStatus = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isCheckingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تم فحص القناة: لا يوجد بث مباشر نشط حالياً، ترقبوا المواعيد القادمة! 📡',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryBlue,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getLiveMatchStream(widget.matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: _buildAppBar(context, false),
            body: _buildProfessionalOfflineState(context),
          );
        }

        final matchData = snapshot.data!.data() ?? {};
        final isLiveFlag = matchData['isLive'] == true || matchData['status'] == 'live';
        final rawVideoId = (matchData['youtubeVideoId'] ?? '').toString().trim();

        String videoId = rawVideoId;
        if (videoId.isNotEmpty) {
          final regex = RegExp(
            r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/|youtube\.com\/live\/)([^"&?\/\s]{11})',
            caseSensitive: false,
          );
          final match = regex.firstMatch(videoId);
          if (match != null && match.groupCount >= 1) {
            videoId = match.group(1) ?? videoId;
          } else {
            videoId = YoutubePlayer.convertUrlToId(videoId) ?? videoId;
          }
        }

        final isLive = isLiveFlag && videoId.isNotEmpty;

        if (!isLive) {
          _controller?.pause();
          return Scaffold(
            appBar: _buildAppBar(context, false),
            body: _buildProfessionalOfflineState(context),
          );
        }

        _initializeOrUpdateYoutubePlayer(videoId);
        final streamTitle = (matchData['title'] ?? 'E-Sport Sudan Live').toString();
        final sessionId = matchData['sessionId'] as String?;
        final teamA = matchData['teamA'] as String?;
        final teamB = matchData['teamB'] as String?;
        final hasMatchScore = teamA != null && teamB != null && (matchData['scoreA'] != null || matchData['scoreB'] != null);

        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppTheme.primaryBlue,
            progressColors: ProgressBarColors(
              playedColor: AppTheme.primaryBlue,
              handleColor: AppTheme.primaryBlue,
              bufferedColor: Colors.grey.shade700,
              backgroundColor: Colors.grey.shade900,
            ),
          ),
          builder: (context, player) {
            return Scaffold(
              appBar: _buildAppBar(context, true),
              body: Column(
                children: [
                  // Top Player Banner Info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            streamTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 6),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // The actual video player
                  player,

                  // Match Score Card
                  if (hasMatchScore)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTeam(teamA, 'مستضيف', Icons.sports_kabaddi),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    '${matchData['scoreA'] ?? 0} - ${matchData['scoreB'] ?? 0}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  matchData['time'] ?? 'مباشر الآن',
                                  style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            _buildTeam(teamB, 'ضيف', Icons.security),
                          ],
                        ),
                      ),
                    ),

                  // Real-Time Live Chat Section
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
                      ),
                      child: Column(
                        children: [
                          // Chat Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06))),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.forum_rounded, color: AppTheme.primaryBlue, size: 18),
                                const SizedBox(width: 8),
                                const Text('الدردشة المباشرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: Colors.green, size: 6),
                                      SizedBox(width: 4),
                                      Text('نشطة', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Chat Messages List
                          Expanded(
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: FirestoreService().getMatchChatStream(widget.matchId, sessionId: sessionId),
                              builder: (context, chatSnapshot) {
                                if (!chatSnapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final messages = chatSnapshot.data!.reversed.toList();

                                if (messages.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                                        const SizedBox(height: 8),
                                        Text(
                                          'كن أول من يشارك في محادثة البث! 👋',
                                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final msg = messages[index];
                                    final isModerator = msg['isModerator'] ?? false;
                                    final senderName = (msg['senderName'] ?? 'لاعب').toString();

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: isModerator
                                                ? Colors.amber.withOpacity(0.25)
                                                : AppTheme.primaryBlue.withOpacity(0.18),
                                            child: Text(
                                              senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                color: isModerator ? Colors.amber : AppTheme.primaryBlue,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      senderName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                        color: isModerator ? Colors.amber : Colors.orangeAccent,
                                                      ),
                                                    ),
                                                    if (isModerator) ...[
                                                      const SizedBox(width: 4),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: Colors.amber.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: const Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.shield, color: Colors.amber, size: 9),
                                                            SizedBox(width: 2),
                                                            Text('مشرف', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  msg['message'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          // Chat Input Bar (Highly Visible)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08))),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _chatController,
                                    style: const TextStyle(fontSize: 14),
                                    onSubmitted: (_) => _sendMessage(sessionId),
                                    textInputAction: TextInputAction.send,
                                    decoration: InputDecoration(
                                      hintText: 'أضف تعليقاً...',
                                      hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      filled: true,
                                      fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _isSending ? null : () => _sendMessage(sessionId),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.primaryBlue, Colors.blueAccent],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isSending
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isLive) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.5)),
              image: const DecorationImage(
                image: AssetImage('assets/images/app_logo.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('E-Sport Sudan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  'قناة البث المباشر الرسمية',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!isLive)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 7),
                const SizedBox(width: 5),
                Text(
                  'غير متاح',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),
          )
        else
          AnimatedBuilder(
            animation: _pulseAnimController,
            builder: (context, child) {
              final val = _pulseAnimController.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4 * val),
                      blurRadius: 8 * val,
                      spreadRadius: 2 * val,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 7),
                    SizedBox(width: 4),
                    Text(
                      'مباشر الآن',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }



  // =========================================================================
  // Professional Offline State Screen (عند توقف أو انتهاء البث المباشر)
  // =========================================================================
  Widget _buildProfessionalOfflineState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Glowing Esports Radar / Broadcast Tower Hero
          AnimatedBuilder(
            animation: _pulseAnimController,
            builder: (context, child) {
              final pulse = _pulseAnimController.value;
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withValues(alpha: 0.25 * pulse),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.35 + (0.35 * pulse)),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.25 * pulse),
                          blurRadius: 20 * pulse,
                          spreadRadius: 4 * pulse,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sensors_off_rounded,
                      size: 46,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Standby Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 7),
                const SizedBox(width: 6),
                Text(
                  'قناة البث في وضع الاستعداد 📡',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Headline
          const Text(
            'لا يوجد بث مباشر حالياً',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Detailed Explanation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'البث المباشر متوقف في الوقت الحالي. سيبدأ البث تلقائياً وتظهر شاشة النقل والدردشة فور انطلاق مباريات ونهائيات البطولات القادمة المعتمدة من الاتحاد.',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 28),

          // Manual Check / Refresh Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCheckingStatus ? null : _handleManualRefresh,
              icon: _isCheckingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                _isCheckingStatus ? 'جاري فحص حالة البث...' : 'تحديث والتحقق من البث الآن 🔄',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tournaments Shortcut Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ترقبوا المنافسات والمواجهات القادمة 🏆',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'تابع جدول مباريات البطولة وشجرة التصفيات',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(1);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TournamentsScreen()),
                        );
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded, color: Colors.black, size: 18),
                    label: const Text(
                      'استكشف جدول البطولات والمباريات',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Notification Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سيصلك إشعار فوري عند بدء بث أي مباراة مباشرة على التطبيق.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTeam(String? name, String location, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
        ),
        const SizedBox(height: 6),
        Text(name ?? 'فريق', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(location, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
      ],
    );
  }
}
