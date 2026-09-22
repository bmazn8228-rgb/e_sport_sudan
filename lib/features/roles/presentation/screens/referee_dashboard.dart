import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class RefereeDashboard extends StatefulWidget {
  const RefereeDashboard({super.key});

  @override
  State<RefereeDashboard> createState() => _RefereeDashboardState();
}

class _RefereeDashboardState extends State<RefereeDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _refereeUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic>? _selectedMatch;
  int _scoreA = 0;
  int _scoreB = 0;
  File? _screenshotFile;
  bool _isSubmitting = false;

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
        const SnackBar(content: Text('يجب رفع لقطة شاشة النتيجة أولاً'), backgroundColor: Colors.orange),
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
            content: Text('تم توثيق النتيجة بنجاح!', style: TextStyle(color: Colors.black)),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
        setState(() { _selectedMatch = null; _scoreA = 0; _scoreB = 0; _screenshotFile = null; _isSubmitting = false; });
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
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
            child: const Text('حكم ساحة', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مباراتي الموكلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                    child: const Center(child: Column(children: [
                      Icon(Icons.sports, size: 40, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('لا توجد مباراة موكلة لك حالياً', style: TextStyle(color: Colors.white54)),
                      SizedBox(height: 4),
                      Text('سيقوم المنظم بتخصيص مباراة لك قريباً', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ])),
                  );
                }
                return Column(children: matches.map((match) {
                  final isSelected = _selectedMatch?['id'] == match['id'];
                  return GestureDetector(
                    onTap: () => setState(() { _selectedMatch = isSelected ? null : match; _scoreA = 0; _scoreB = 0; _screenshotFile = null; }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.white12, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.sports_score, color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${match["teamA"] ?? "فريق أ"} vs ${match["teamB"] ?? "فريق ب"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(match['tournamentName'] ?? 'بطولة', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ])),
                        if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 20),
                      ]),
                    ),
                  );
                }).toList());
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTeamScore(_selectedMatch!['teamA'] ?? 'فريق أ', _scoreA, (v) => setState(() => _scoreA = v)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                      child: const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 18))),
                    _buildTeamScore(_selectedMatch!['teamB'] ?? 'فريق ب', _scoreB, (v) => setState(() => _scoreB = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('رفع لقطة شاشة النتيجة (إلزامي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_screenshotFile != null ? Icons.check_circle : Icons.upload_file,
                        color: _screenshotFile != null ? AppTheme.primaryBlue : Colors.white54),
                    const SizedBox(width: 12),
                    Text(_screenshotFile != null ? 'تم اختيار الصورة' : 'اضغط لاختيار صورة النتيجة',
                        style: TextStyle(color: _screenshotFile != null ? AppTheme.primaryBlue : Colors.white54)),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitResult,
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.verified_user),
                  label: Text(_isSubmitting ? 'جاري الحفظ...' : 'التوقيع الإلكتروني واعتماد النتيجة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScore(String name, int score, ValueChanged<int> onScoreChange) {
    return Column(children: [
      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Row(children: [
        IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white54), onPressed: score > 0 ? () => onScoreChange(score - 1) : null),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: Text('$score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ),
        IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue), onPressed: () => onScoreChange(score + 1)),
      ]),
    ]);
  }
}
