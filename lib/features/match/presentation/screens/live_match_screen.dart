import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveMatchScreen extends StatefulWidget {
  final String matchId;
  const LiveMatchScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  YoutubePlayerController? _controller;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentVideoId = '';

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

  void _sendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _chatController.clear();

    await FirestoreService().sendChatMessage(
      matchId: widget.matchId,
      senderId: user.uid,
      senderName: user.displayName ?? 'لاعب',
      message: message,
    );

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('E-Sport Sudan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('البث المباشر', style: TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text('مباشر الآن', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().getLiveMatchStream(widget.matchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('يتوفر قريباً', style: TextStyle(color: Colors.white54, fontSize: 18)));
          }

          final matchData = snapshot.data!.data()!;
          _initializeOrUpdateYoutubePlayer(matchData['youtubeVideoId'] ?? '');

          return Column(
            children: [
              // Video Player
              Container(
                height: 220,
                color: Colors.black,
                child: Stack(
                  children: [
                    if (_controller != null)
                      YoutubePlayer(
                        controller: _controller!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: AppTheme.primaryGreen,
                        progressColors: const ProgressBarColors(
                          playedColor: AppTheme.primaryGreen,
                          handleColor: AppTheme.primaryGreen,
                        ),
                      )
                    else
                      const Center(child: Text('البث لم يبدأ بعد', style: TextStyle(color: Colors.white))),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.red,
                        child: const Text('YouTube Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTeam(matchData['teamA'] ?? 'فريق أ', 'مستضيف', Icons.sports_kabaddi),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                            child: Text('${matchData['scoreA']} - ${matchData['scoreB']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          const SizedBox(height: 8),
                          Text(matchData['time'] ?? 'منتظر', style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    children: [
                      // Chat Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.forum, color: AppTheme.primaryGreen, size: 18),
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
                              return const Center(child: CircularProgressIndicator());
                            }
                            final messages = chatSnapshot.data!;
                            
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final isModerator = msg['isModerator'] ?? false;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                                        child: Text((msg['senderName'] ?? '?')[0].toString().toUpperCase(), style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12)),
                                      ),
                                      const SizedBox(width: 10),
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
                                                    color: isModerator ? AppTheme.primaryGreen : Colors.orange
                                                  )
                                                ),
                                                if (isModerator) ...[
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 12),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(msg['message'] ?? '', style: const TextStyle(fontSize: 13)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          border: Border(top: BorderSide(color: Colors.white12)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                style: const TextStyle(fontSize: 13),
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: 'اكتب رسالة...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Colors.white54),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.black, size: 18),
                                onPressed: _sendMessage,
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
        CircleAvatar(radius: 20, backgroundColor: Colors.white12, child: Icon(icon, color: Colors.white)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(location, style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}
