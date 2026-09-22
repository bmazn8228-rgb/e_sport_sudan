import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';

class RefereeDashboardScreen extends StatelessWidget {
  const RefereeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الحكم', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getAllMatchesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return const Center(child: Text('لا توجد مباريات حالياً'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(match['title'] ?? 'مباراة', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${match['scoreA']} - ${match['scoreB']} | ${match['status']}'),
                  trailing: const Icon(Icons.settings, color: AppTheme.primaryBlue),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchControlRoom(matchId: match['id'], initialData: match),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MatchControlRoom extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> initialData;

  const MatchControlRoom({super.key, required this.matchId, required this.initialData});

  @override
  State<MatchControlRoom> createState() => _MatchControlRoomState();
}

class _MatchControlRoomState extends State<MatchControlRoom> {
  late TextEditingController _youtubeController;
  late TextEditingController _timeController;
  late int _scoreA;
  late int _scoreB;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _youtubeController = TextEditingController(text: widget.initialData['youtubeVideoId'] ?? '');
    _timeController = TextEditingController(text: widget.initialData['time'] ?? '');
    _scoreA = widget.initialData['scoreA'] ?? 0;
    _scoreB = widget.initialData['scoreB'] ?? 0;
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _updateScore() async {
    setState(() => _isLoading = true);
    try {
      await FirestoreService().updateMatchScore(
        widget.matchId,
        _scoreA,
        _scoreB,
        _timeController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث النتيجة بنجاح', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديث النتيجة', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateStreamUrl() async {
    final rawInput = _youtubeController.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رابط أو معرّف فيديو YouTube ⚠️'), backgroundColor: Colors.red),
      );
      return;
    }
    final videoId = YoutubePlayer.convertUrlToId(rawInput) ?? rawInput;

    setState(() => _isLoading = true);
    try {
      await FirestoreService().updateMatchStreamUrl(
        widget.matchId,
        videoId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث رابط البث المباشر بنجاح ✅', style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryBlue));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل تحديث رابط البث ❌', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData['title'] ?? 'غرفة التحكم'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('إدارة النتيجة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Team A
                      Column(
                        children: [
                          Text(widget.initialData['teamA'] ?? 'الفريق أ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  if (_scoreA > 0) setState(() => _scoreA--);
                                },
                              ),
                              Text('$_scoreA', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () {
                                  setState(() => _scoreA++);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                      const Text('VS', style: TextStyle(color: Colors.grey)),
                      // Team B
                      Column(
                        children: [
                          Text(widget.initialData['teamB'] ?? 'الفريق ب', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  if (_scoreB > 0) setState(() => _scoreB--);
                                },
                              ),
                              Text('$_scoreB', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: () {
                                  setState(() => _scoreB++);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'وقت المباراة (مثلاً 78\')',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                      onPressed: _isLoading ? null : _updateScore,
                      child: const Text('تحديث النتيجة والوقت', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Video Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إدارة البث', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _youtubeController,
                    decoration: const InputDecoration(
                      labelText: 'YouTube Video ID',
                      helperText: 'مثال: jfKfPfyJRdk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: _isLoading ? null : _updateStreamUrl,
                      child: const Text('تحديث رابط البث المباشر', style: TextStyle(color: Colors.white)),
                    ),
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
