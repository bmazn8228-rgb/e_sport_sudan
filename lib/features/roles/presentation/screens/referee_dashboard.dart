import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:e_sport_sudan/core/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/referee_dashboard_screen.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/core/widgets/live_matches_section.dart';

class RefereeDashboard extends StatefulWidget {
  RefereeDashboard({super.key});

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
        SnackBar(content: Text('يجب رفع لقطة شاشة النتيجة أولاً للتحقق من النزاهة'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final screenshotUrl = await StorageService().uploadImage(
        _screenshotFile!,
        'match_results',
      );
      if (screenshotUrl == null) {
        throw Exception('فشل في رفع لقطة الشاشة');
      }
      await _firestoreService.submitMatchResult(
        matchId: _selectedMatch!['id'],
        scoreA: _scoreA,
        scoreB: _scoreB,
        screenshotUrl: screenshotUrl,
        refereeId: _refereeUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
        title: Text('لوحة تحكم الحكم المعتمد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج',
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
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
          tabs: [
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المباريات الموكلة لي للتحكيم والتوثيق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getMatchesForRefereeStream(_refereeUid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
              }
              final matches = snapshot.data ?? [];
              if (matches.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10))),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.sports, size: 40, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                        SizedBox(height: 12),
                        Text('لا توجد مباراة موكلة لك حالياً', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('سيقوم منظم البطولة بتخصيص مباريات لك أو يمكنك التبديل إلى تبويب "غرفة التحكم المباشر" لإدارة أي مباراة مباشرة.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12)),
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
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12), width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.sports_score, color: Colors.blue, size: 20),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${match["teamA"] ?? "فريق أ"} vs ${match["teamB"] ?? "فريق ب"}', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('${match['tournamentName'] ?? 'بطولة'} • ${match['round'] ?? 'مباراة'}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                              ],
                            ),
                          ),
                          if (isSelected) Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (_selectedMatch != null) ...[
            SizedBox(height: 24),
            Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
            SizedBox(height: 16),
            Text(
              'تسجيل نتيجة: ${_selectedMatch!["teamA"] ?? "فريق أ"} vs ${_selectedMatch!["teamB"] ?? "فريق ب"}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTeamScore(_selectedMatch!['teamA'] ?? 'فريق أ', _scoreA, (v) => setState(() => _scoreA = v)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: Text('VS', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  _buildTeamScore(_selectedMatch!['teamB'] ?? 'فريق ب', _scoreB, (v) => setState(() => _scoreB = v)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('رفع لقطة شاشة النتيجة (إلزامي للتوثيق والنزاهة):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _screenshotFile != null ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_screenshotFile != null ? Icons.check_circle : Icons.upload_file, color: _screenshotFile != null ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                    SizedBox(width: 12),
                    Text(_screenshotFile != null ? 'تم اختيار لقطة الشاشة بنجاح' : 'اضغط لاختيار صورة النتيجة من المعرض', style: TextStyle(color: _screenshotFile != null ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitResult,
                icon: _isSubmitting
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Icon(Icons.cloud_upload, color: Colors.black),
                label: Text(_isSubmitting ? 'جاري رفع النتيجة...' : 'توثيق واعتماد النتيجة نهائياً 🚀', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveControlRoomView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
          child: LiveMatchesSection(),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getAllMatchesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final matches = snapshot.data ?? [];
        if (matches.isEmpty) {
          return Center(child: Text('لا توجد مباريات حالياً في النظام', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            final status = match['status'] ?? 'scheduled';
            final isLive = status == 'live';

            return Card(
              color: Theme.of(context).colorScheme.surface,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLive ? Colors.red : Colors.blue.withValues(alpha: 0.2),
                  child: Icon(isLive ? Icons.live_tv : Icons.sports_score, color: isLive ? Theme.of(context).colorScheme.onSurface : Colors.blue),
                ),
                title: Text('${match['teamA'] ?? 'فريق أ'} VS ${match['teamB'] ?? 'فريق ب'}', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('النتيجة: ${match['scoreA'] ?? 0} - ${match['scoreB'] ?? 0} | ${match['time'] ?? 'مجدولة'}'),
                trailing: Icon(Icons.tune, color: AppTheme.primaryBlue),
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
    ), // This closes Expanded
    ],
    );
  }

  Widget _buildTeamScore(String teamName, int score, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(teamName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: score > 0 ? () => onChanged(score - 1) : null,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: Text('$score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.greenAccent),
              onPressed: () => onChanged(score + 1),
            ),
          ],
        ),
      ],
    );
  }
}
