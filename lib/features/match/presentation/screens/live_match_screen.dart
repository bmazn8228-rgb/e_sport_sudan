import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveMatchScreen extends StatefulWidget {
  final String matchId;
  const LiveMatchScreen({super.key, required this.matchId});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  YoutubePlayerController? _controller;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentVideoId = '';
  bool _isSending = false;

  @override
  void dispose() {
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
          flags: YoutubePlayerFlags(
            isLive: true,
            autoPlay: true,
            mute: true, // Muted by default to prevent sudden noise
            forceHD: false,
          ),
        );
      }
    }
  }

  void _sendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await FirestoreService().sendChatMessage(
        matchId: widget.matchId,
        senderId: user.uid,
        senderName: user.displayName ?? 'لاعب',
        message: message,
      );

      _chatController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إرسال الرسالة ❌', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(radius: 16, backgroundImage: AssetImage('assets/images/app_logo.jpg'), backgroundColor: Colors.transparent),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E-Sport Sudan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('البث المباشر', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirestoreService().getLiveMatchStream(widget.matchId),
            builder: (context, snapshot) {
              final isLive = (snapshot.hasData && snapshot.data!.exists) ? (snapshot.data!.data()!['isLive'] == true) : false;
              if (!isLive) return SizedBox.shrink();
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.0),
                duration: Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                builder: (context, val, child) {
                  return Opacity(
                    opacity: val,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5 * val),
                            blurRadius: 8 * val,
                            spreadRadius: 2 * val,
                          )
                        ]
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text('مباشر الآن', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().getLiveMatchStream(widget.matchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_off, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 64),
                    SizedBox(height: 16),
                    Text('لا يوجد بث مباشر نشط حالياً', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('سيبدأ البث فور قيام إدارة البطولة بنقل المباريات', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final matchData = snapshot.data!.data()!;
          final isLive = matchData['isLive'] == true;
          final rawVideoId = (matchData['youtubeVideoId'] ?? '').toString().trim();
          
          String videoId = rawVideoId;
          if (videoId.isNotEmpty) {
            final regex = RegExp(r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/|youtube\.com\/live\/)([^"&?\/\s]{11})', caseSensitive: false);
            final match = regex.firstMatch(videoId);
            if (match != null && match.groupCount >= 1) {
              videoId = match.group(1) ?? videoId;
            } else {
              videoId = YoutubePlayer.convertUrlToId(videoId) ?? videoId;
            }
          }
          
          if (videoId.isNotEmpty && isLive) {
            _initializeOrUpdateYoutubePlayer(videoId);
          }

          final streamTitle = matchData['title'] ?? 'E-Sport Sudan';

          return Column(
            children: [
              // Video Player Header Info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        streamTitle,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLive ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Theme.of(context).colorScheme.onSurface, size: 8),
                          SizedBox(width: 4),
                          Text(isLive ? 'مباشر الآن' : 'البث متوقف', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Video Player
              Container(
                height: 220,
                color: Colors.black,
                child: Stack(
                  children: [
                    if (_controller != null && isLive && videoId.isNotEmpty)
                      YoutubePlayer(
                        controller: _controller!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: AppTheme.primaryBlue,
                        progressColors: ProgressBarColors(
                          playedColor: AppTheme.primaryBlue,
                          handleColor: AppTheme.primaryBlue,
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.live_tv, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), size: 48),
                            SizedBox(height: 8),
                            Text('البث المباشر متوقف حالياً أو لم يبدأ بعد', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14)),
                          ],
                        ),
                      ),
                    if (isLive && videoId.isNotEmpty)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.red,
                          child: Text('YouTube Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTeam(matchData['teamA'] ?? 'فريق أ', 'مستضيف', Icons.sports_kabaddi),
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                            child: Text('${matchData['scoreA']} - ${matchData['scoreB']}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          SizedBox(height: 8),
                          Text(matchData['time'] ?? 'منتظر', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                        ],
                      ),
                      _buildTeam(matchData['teamB'] ?? 'فريق ب', 'ضيف', Icons.security),
                    ],
                  ),
                ),
              ),
              // Live Chat Section
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      // Chat Header
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.forum, color: AppTheme.primaryBlue, size: 18),
                            SizedBox(width: 8),
                            Text('الدردشة المباشرة', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // Chat Messages List
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: FirestoreService().getMatchChatStream(widget.matchId),
                          builder: (context, chatSnapshot) {
                            if (!chatSnapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            final messages = chatSnapshot.data!.reversed.toList();
                            
                            return ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: EdgeInsets.all(12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isModerator = msg['isModerator'] ?? false;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                                        child: Text((msg['senderName'] ?? '?')[0].toString().toUpperCase(), style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  msg['senderName'] ?? 'مجهول', 
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold, 
                                                    fontSize: 12, 
                                                    color: isModerator ? AppTheme.primaryBlue : Colors.orange
                                                  )
                                                ),
                                                if (isModerator) ...[
                                                  SizedBox(width: 4),
                                                  Icon(Icons.verified, color: AppTheme.primaryBlue, size: 12),
                                                ],
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(msg['message'] ?? '', style: TextStyle(fontSize: 13)),
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
                      // Chat Input Area
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                style: TextStyle(fontSize: 13),
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'اكتب رسالة...',
                                  hintStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: _isSending
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                      )
                                    : Icon(Icons.send, color: Colors.black, size: 18),
                                onPressed: _isSending ? null : _sendMessage,
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
          );
        }
      ),
    );
  }

  Widget _buildTeam(String name, String location, IconData icon) {
    return Column(
      children: [
        CircleAvatar(radius: 20, backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12), child: Icon(icon, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(height: 8),
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(location, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
      ],
    );
  }
}
