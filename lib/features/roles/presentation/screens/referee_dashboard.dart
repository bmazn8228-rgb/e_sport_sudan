import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/referee_dashboard_screen.dart';

class RefereeDashboard extends StatefulWidget {
  const RefereeDashboard({super.key});

  @override
  State<RefereeDashboard> createState() => _RefereeDashboardState();
}

class _RefereeDashboardState extends State<RefereeDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final String _refereeUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic>? _selectedMatch;
  int _scoreA = 0;
  int _scoreB = 0;
  File? _screenshotFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _screenshotFile = File(picked.path));
    }
  }

  Future<void> _submitResult() async {
    if (_selectedMatch == null) return;
    if (_screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب رفع لقطة شاشة النتيجة أولاً للتحقق من النزاهة'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final fileName = '${_refereeUid}_${_selectedMatch!["id"]}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('match_results/$fileName');
      await ref.putFile(_screenshotFile!);
      final screenshotUrl = await ref.getDownloadURL();
      await _firestoreService.submitMatchResult(
        matchId: _selectedMatch!['id'],
        scoreA: _scoreA,
        scoreB: _scoreB,
        screenshotUrl: screenshotUrl,
        refereeId: _refereeUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم توثيق النتيجة ورفع الإثبات بنجاح في Firebase! ✅', style: TextStyle(color: Colors.black)),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
        setState(() {
          _selectedMatch = null;
          _scoreA = 0;
          _scoreB = 0;
          _screenshotFile = null;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('لوحة تحكم الحكم المعتمد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'مبارياتي الموكلة ⚖️'),
            Tab(text: 'غرفة التحكم المباشر 📡'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Assigned Matches with Verification Screenshot Upload
          _buildAssignedMatchesView(),

          // Tab 2: Match Control Room (Live scores & YouTube stream URL)
          _buildLiveControlRoomView(),
        ],
      ),
    );
  }

  Widget _buildAssignedMatchesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المباريات الموكلة لي للتحكيم والتوثيق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getMatchesForRefereeStream(_refereeUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
              }
              final matches = snapshot.data ?? [];
              if (matches.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.sports, size: 40, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('لا توجد مباراة موكلة لك حالياً', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('سيقوم منظم البطولة بتخصيص مباريات لك أو يمكنك التبديل إلى تبويب "غرفة التحكم المباشر" لإدارة أي مباراة مباشرة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: matches.map((match) {
                  final isSelected = _selectedMatch?['id'] == match['id'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedMatch = isSelected ? null : match;
                      _scoreA = (match['scoreA'] as num?)?.toInt() ?? 0;
                      _scoreB = (match['scoreB'] as num?)?.toInt() ?? 0;
                      _screenshotFile = null;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.white12, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.sports_score, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${match["teamA"] ?? "فريق أ"} vs ${match["teamB"] ?? "فريق ب"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${match['tournamentName'] ?? 'بطولة'} • ${match['round'] ?? 'مباراة'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (_selectedMatch != null) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              'تسجيل نتيجة: ${_selectedMatch!["teamA"] ?? "فريق أ"} vs ${_selectedMatch!["teamB"] ?? "فريق ب"}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTeamScore(_selectedMatch!['teamA'] ?? 'فريق أ', _scoreA, (v) => setState(() => _scoreA = v)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  _buildTeamScore(_selectedMatch!['teamB'] ?? 'فريق ب', _scoreB, (v) => setState(() => _scoreB = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('رفع لقطة شاشة النتيجة (إلزامي للتوثيق والنزاهة):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _screenshotFile != null ? AppTheme.primaryBlue : Colors.white24, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_screenshotFile != null ? Icons.check_circle : Icons.upload_file, color: _screenshotFile != null ? AppTheme.primaryBlue : Colors.white54),
                    const SizedBox(width: 12),
                    Text(_screenshotFile != null ? 'تم اختيار لقطة الشاشة بنجاح' : 'اضغط لاختيار صورة النتيجة من المعرض', style: TextStyle(color: _screenshotFile != null ? AppTheme.primaryBlue : Colors.white54)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitResult,
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.cloud_upload, color: Colors.black),
                label: Text(_isSubmitting ? 'جاري رفع النتيجة...' : 'توثيق واعتماد النتيجة نهائياً 🚀', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveControlRoomView() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getAllMatchesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final matches = snapshot.data ?? [];
        if (matches.isEmpty) {
          return const Center(child: Text('لا توجد مباريات حالياً في النظام', style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final status = match['status'] ?? 'scheduled';
            final isLive = status == 'live';

            return Card(
              color: AppTheme.cardDark,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLive ? Colors.red : Colors.blue.withValues(alpha: 0.2),
                  child: Icon(isLive ? Icons.live_tv : Icons.sports_score, color: isLive ? Colors.white : Colors.blue),
                ),
                title: Text('${match['teamA'] ?? 'فريق أ'} VS ${match['teamB'] ?? 'فريق ب'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('النتيجة: ${match['scoreA'] ?? 0} - ${match['scoreB'] ?? 0} | ${match['time'] ?? 'مجدولة'}'),
                trailing: const Icon(Icons.tune, color: AppTheme.primaryBlue),
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
    );
  }

  Widget _buildTeamScore(String teamName, int score, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: score > 0 ? () => onChanged(score - 1) : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: Text('$score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
              onPressed: () => onChanged(score + 1),
            ),
          ],
        ),
      ],
    );
  }
}
