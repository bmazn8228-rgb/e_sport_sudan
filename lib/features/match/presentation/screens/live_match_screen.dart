import 'dart:math';
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

class _LiveMatchScreenState extends State<LiveMatchScreen> with TickerProviderStateMixin {
  YoutubePlayerController? _controller;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentVideoId = '';
  String? _selectedMatchId;
  bool _isSending = false;
  bool _isCheckingStatus = false;
  bool _showCommentsOverlay = true;

  UserModel? _currentUserModel;
  late AnimationController _pulseAnimController;

  // Floating Hearts List for TikTok Reaction Animation
  final List<_FloatingHeartItem> _hearts = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _selectedMatchId = widget.matchId;
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _preloadUserData();
  }

  void _preloadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirestoreService().getUser(user.uid);
        if (mounted) {
          setState(() {
            _currentUserModel = doc;
          });
        }
      } catch (_) {}
    }
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

  void _sendMessage(String? currentSessionId, String targetMatchId) async {
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
      final role = _currentUserModel?.role ?? UserRole.player;
      final isMod = role != UserRole.player;
      final senderName = _currentUserModel?.displayName.isNotEmpty == true
          ? _currentUserModel!.displayName
          : (user.displayName ?? 'لاعب');

      await FirestoreService().sendChatMessage(
        matchId: targetMatchId,
        senderId: user.uid,
        senderName: senderName,
        senderRole: role.toValue(),
        message: message,
        sessionId: currentSessionId,
        isModerator: isMod,
      );

      _chatController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إرسال الرسالة: $e ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  void _emitHeartReaction() {
    HapticFeedback.lightImpact();
    setState(() {
      _hearts.add(
        _FloatingHeartItem(
          id: DateTime.now().microsecondsSinceEpoch,
          color: [
            Colors.redAccent,
            Colors.pinkAccent,
            Colors.purpleAccent,
            Colors.orangeAccent,
            AppTheme.primaryBlue,
          ][_random.nextInt(5)],
          size: 24.0 + _random.nextDouble() * 14.0,
          horizontalShift: (_random.nextDouble() - 0.5) * 60,
        ),
      );
    });
  }

  void _handleManualRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isCheckingStatus = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isCheckingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService().getActiveLiveStreams(),
      builder: (context, activeSnapshot) {
        final activeStreams = activeSnapshot.data ?? [];

        // If no streams are live at all, show professional offline state
        if (activeStreams.isEmpty) {
          _controller?.pause();
          return Scaffold(
            appBar: _buildAppBar(context, false, activeStreams),
            body: _buildProfessionalOfflineState(context, activeStreams),
          );
        }

        // Determine effective active stream ID
        String effectiveId = _selectedMatchId ?? widget.matchId;
        Map<String, dynamic>? activeMatchData = activeStreams.firstWhere(
          (m) => m['id'] == effectiveId,
          orElse: () => activeStreams.first,
        );

        effectiveId = activeMatchData['id'] ?? activeStreams.first['id'];

        final rawVideoId = (activeMatchData['youtubeVideoId'] ?? '').toString().trim();
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

        final streamTitle = (activeMatchData['title'] ?? 'E-Sport Sudan Live').toString();
        final refereeName = activeMatchData['refereeName'] as String?;
        final sessionId = activeMatchData['sessionId'] as String?;
        final teamA = activeMatchData['teamA'] as String?;
        final teamB = activeMatchData['teamB'] as String?;
        final scoreA = activeMatchData['scoreA'];
        final scoreB = activeMatchData['scoreB'];
        final hasMatchScore = teamA != null && teamB != null && (scoreA != null || scoreB != null);

        _initializeOrUpdateYoutubePlayer(videoId);

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
              resizeToAvoidBottomInset: true,
              appBar: _buildAppBar(context, true, activeStreams),
              body: Stack(
                children: [
                  // Background Main Column
                  Column(
                    children: [
                      // Multi-Stream Top Switcher (if > 1 live stream)
                      if (activeStreams.length > 1)
                        _buildMultiStreamSwitcher(activeStreams, effectiveId),

                      // Stream Info Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        color: Colors.black.withValues(alpha: 0.6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: Colors.white, size: 6),
                                  SizedBox(width: 4),
                                  Text(
                                    'مباشر',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    streamTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (refereeName != null && refereeName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.gavel_rounded, size: 11, color: Colors.greenAccent),
                                        const SizedBox(width: 4),
                                        Text(
                                          'الحكم: $refereeName',
                                          style: const TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _showCommentsOverlay ? Icons.subtitles_rounded : Icons.subtitles_off_rounded,
                                color: _showCommentsOverlay ? AppTheme.primaryBlue : Colors.white60,
                                size: 20,
                              ),
                              tooltip: _showCommentsOverlay ? 'إخفاء التعليقات' : 'إظهار التعليقات',
                              onPressed: () => setState(() => _showCommentsOverlay = !_showCommentsOverlay),
                            ),
                          ],
                        ),
                      ),

                      // YouTube Player
                      player,

                      // Match Score Banner (if configured)
                      if (hasMatchScore)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  teamA,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  '${scoreA ?? 0} : ${scoreB ?? 0}',
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  teamB,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Spacer to let TikTok-style comments float in the bottom area
                      Expanded(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),

                  // TikTok-Style Floating Comments & Bottom Actions Overlay
                  if (_showCommentsOverlay)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildTikTokCommentsOverlay(sessionId, effectiveId),
                    ),

                  // Floating Hearts Display (TikTok Reactions)
                  Positioned(
                    right: 20,
                    bottom: 80,
                    child: SizedBox(
                      width: 100,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: _hearts.map((heart) {
                          return _FloatingHeartWidget(
                            key: ValueKey(heart.id),
                            heart: heart,
                            onComplete: () {
                              if (mounted) {
                                setState(() => _hearts.remove(heart));
                              }
                            },
                          );
                        }).toList(),
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

  // =========================================================================
  // Multi-Stream Switcher Bar (عرض والتبديل بين أكثر من بث مباشر احترافياً)
  // =========================================================================
  Widget _buildMultiStreamSwitcher(List<Map<String, dynamic>> streams, String activeId) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131822),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: streams.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final stream = streams[idx];
          final isSelected = stream['id'] == activeId;
          final title = stream['title'] ?? 'بث مباشر ${idx + 1}';

          return InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedMatchId = stream['id'];
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.redAccent : Colors.white.withValues(alpha: 0.15),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 7,
                    color: isSelected ? Colors.white : Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // TikTok-Style Comments & Bottom Bar Overlay
  // =========================================================================
  Widget _buildTikTokCommentsOverlay(String? sessionId, String activeMatchId) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stream Comments List (Floating TikTok Bubbles)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getMatchChatStream(activeMatchId, sessionId: sessionId),
              builder: (context, chatSnapshot) {
                if (!chatSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final messages = chatSnapshot.data!.reversed.toList();

                if (messages.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.waving_hand_rounded, color: AppTheme.primaryBlue, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'مرحباً بك! كن أول من يكتب تعليقاً في هذا البث 💬',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildTikTokMessageBubble(msg);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Bottom TikTok Input & Actions Capsule
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  // Text Input Capsule
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              style: const TextStyle(fontSize: 13, color: Colors.white),
                              onSubmitted: (_) => _sendMessage(sessionId, activeMatchId),
                              textInputAction: TextInputAction.send,
                              decoration: InputDecoration(
                                hintText: 'أضف تعليقاً... 💬',
                                hintStyle: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _isSending ? null : () => _sendMessage(sessionId, activeMatchId),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Icon(Icons.send_rounded, color: AppTheme.primaryBlue, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // TikTok Heart Like Button
                  InkWell(
                    onTap: _emitHeartReaction,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TikTok Single Message Bubble (شارة الرتبة + الصورة + النص)
  // =========================================================================
  Widget _buildTikTokMessageBubble(Map<String, dynamic> msg) {
    final senderName = (msg['senderName'] ?? 'لاعب').toString();
    final messageText = (msg['message'] ?? '').toString();
    final roleValue = msg['senderRole'] as String?;
    final isModerator = msg['isModerator'] == true;
    final role = UserRole.fromValue(roleValue);

    Color roleColor;
    String roleBadge;

    if (role == UserRole.superAdmin) {
      roleColor = const Color(0xFFFFD700);
      roleBadge = '👑 مدير النظام';
    } else if (role == UserRole.tournamentAdmin) {
      roleColor = Colors.orangeAccent;
      roleBadge = '🏆 منظم';
    } else if (role == UserRole.referee) {
      roleColor = Colors.cyanAccent;
      roleBadge = '⚖️ حكم';
    } else if (role == UserRole.financeAdmin) {
      roleColor = Colors.greenAccent;
      roleBadge = '💳 مسؤول مالي';
    } else if (isModerator) {
      roleColor = Colors.amberAccent;
      roleBadge = '🛡️ مشرف';
    } else {
      roleColor = AppTheme.primaryBlue;
      roleBadge = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: roleBadge.isNotEmpty ? roleColor.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: roleColor.withValues(alpha: 0.25),
                child: Text(
                  senderName.isNotEmpty ? senderName[0].toUpperCase() : '؟',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: roleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (roleBadge.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              roleBadge,
                              style: TextStyle(color: roleColor, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      messageText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isLive, List<Map<String, dynamic>> activeStreams) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
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
                const Text('E-Sport Sudan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  isLive
                      ? (activeStreams.length > 1 ? '${activeStreams.length} بثوث مباشرة نشطة 🔴' : 'البث المباشر الرسمي 🔴')
                      : 'قناة البث المباشر في وضع الاستعداد',
                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isLive)
          AnimatedBuilder(
            animation: _pulseAnimController,
            builder: (context, child) {
              final val = _pulseAnimController.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4 * val),
                      blurRadius: 8 * val,
                      spreadRadius: 2 * val,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 6),
                    SizedBox(width: 4),
                    Text('LIVE 🔴', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // =========================================================================
  // Professional Offline State Screen
  // =========================================================================
  Widget _buildProfessionalOfflineState(BuildContext context, List<Map<String, dynamic>> activeStreams) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _pulseAnimController,
            builder: (context, child) {
              final pulse = _pulseAnimController.value;
              return Container(
                width: 130,
                height: 130,
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
                    width: 90,
                    height: 90,
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
                          blurRadius: 18 * pulse,
                          spreadRadius: 3 * pulse,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sensors_off_rounded,
                      size: 42,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15)),
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
          const SizedBox(height: 14),
          const Text(
            'لا يوجد بث مباشر حالياً',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'البث المباشر متوقف حالياً. عند بدء أي بث جديد سيظهر فوراً هنا مع خانة التعليقات النظيفة المباشرة.',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCheckingStatus ? null : _handleManualRefresh,
              icon: _isCheckingStatus
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                _isCheckingStatus ? 'جاري الفحص...' : 'التحقق من حالة البث الآن 🔄',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tournaments Shortcut Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ترقبوا المنافسات والمواجهات القادمة 🏆', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('تابع جدول مباريات البطولة وشجرة التصفيات', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(1);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen()));
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded, color: Colors.black, size: 16),
                    label: const Text('استكشف جدول البطولات والمباريات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// =========================================================================
// Floating Heart Model & Animation Widget for TikTok Style Reaction
// =========================================================================
class _FloatingHeartItem {
  final int id;
  final Color color;
  final double size;
  final double horizontalShift;

  _FloatingHeartItem({
    required this.id,
    required this.color,
    required this.size,
    required this.horizontalShift,
  });
}

class _FloatingHeartWidget extends StatefulWidget {
  final _FloatingHeartItem heart;
  final VoidCallback onComplete;

  const _FloatingHeartWidget({super.key, required this.heart, required this.onComplete});

  @override
  State<_FloatingHeartWidget> createState() => _FloatingHeartWidgetState();
}

class _FloatingHeartWidgetState extends State<_FloatingHeartWidget> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final progress = _anim.value;
        final dy = -220 * progress;
        final dx = sin(progress * pi * 2) * widget.heart.horizontalShift;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        final scale = 0.5 + (sin(progress * pi) * 0.7);

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Icon(
                Icons.favorite_rounded,
                color: widget.heart.color,
                size: widget.heart.size,
              ),
            ),
          ),
        );
      },
    );
  }
}
