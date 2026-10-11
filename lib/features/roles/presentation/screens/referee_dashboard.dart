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
import 'package:e_sport_sudan/features/match/presentation/screens/live_match_screen.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';

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

  Future<void> _claimStream(Map<String, dynamic> stream) async {
    final matchId = stream['id'] ?? '';
    final streamTitle = stream['title'] ?? 'البث المباشر';
    final currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'حكم معتمد';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('استلام تحكيم البث ⚖️', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text('هل ترغب في استلام تحكيم "$streamTitle" الآن؟\n\nسيتم تسجيلك كحكم رسمي لهذا البث وإبلاغ المنظمين واللاعبين.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد واستلام التحكيم 🚀', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.claimMatchReferee(
          matchId: matchId,
          refereeId: _refereeUid,
          refereeName: currentUserName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم استلام تحكيم البث بنجاح! تم تعيينك كحكم معتمد ⚖️', style: TextStyle(color: Colors.black)),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchControlRoom(matchId: matchId, initialData: stream),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showCustomToast(context, title: 'خطأ', message: 'فشل استلام التحكيم: $e', type: ToastType.urgent);
        }
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
                        Text('سيقوم منظم البطولة بتخصيص مباريات لك أو يمكنك التبديل إلى تبويب "غرفة التحكم المباشر" لاستلام تحكيم أي بث مباشر.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: matches.map((match) {
                  final isSelected = _selectedMatch?['id'] == match['id'];
                  final isLive = match['isLive'] == true || match['status'] == 'live';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLive
                            ? Colors.redAccent
                            : (isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                        width: isLive || isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Colors.redAccent, size: 8),
                                SizedBox(width: 6),
                                Text(
                                  'بث مباشر نشط الآن 🔴 (أنت الحكم المعين)',
                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedMatch = isSelected ? null : match;
                            _scoreA = (match['scoreA'] as num?)?.toInt() ?? 0;
                            _scoreB = (match['scoreB'] as num?)?.toInt() ?? 0;
                            _screenshotFile = null;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isLive ? Colors.red : Colors.blue).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isLive ? Icons.live_tv_rounded : Icons.sports_score,
                                    color: isLive ? Colors.redAccent : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${match["teamA"] ?? "فريق أ"} vs ${match["teamB"] ?? "فريق ب"}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${match['tournamentName'] ?? 'بطولة'} • ${match['round'] ?? 'مباراة'}${isLive ? ' • النتيجة: ${match['scoreA'] ?? 0} - ${match['scoreB'] ?? 0}' : ''}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: AppTheme.primaryBlue, size: 20),
                              ],
                            ),
                          ),
                        ),
                        if (isLive)
                          Padding(
                            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MatchControlRoom(matchId: match['id'], initialData: match),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.tune_rounded, size: 16, color: Colors.black),
                                    label: const Text('دخول وتحكيم البث ⚖️', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LiveMatchScreen(matchId: match['id']),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.live_tv, size: 16, color: Colors.white),
                                  label: const Text('مشاهدة ودردشة 💬', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.live_tv_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'البثوث المباشرة النشطة (غرفة الحكام) 📡',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'اختر البث الذي تود تحكيمه. عند انشغال حكم بزميل، يمكنك تحكيم بث آخر شاغر.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
          ),
          const SizedBox(height: 12),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getActiveLiveStreams(),
            builder: (context, activeSnap) {
              if (activeSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  ),
                );
              }

              final activeStreams = activeSnap.data ?? [];

              if (activeStreams.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.tv_off_rounded, size: 36, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        const Text(
                          'لا توجد بثوث مباشرة جارية حالياً',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'فور بدء أي بث مباشر من الإدارة سيظهر هنا لجميع الحكام فوراً.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: activeStreams.map((st) {
                  final stId = (st['id'] ?? '').toString();
                  final stTitle = (st['title'] ?? 'بث مباشر').toString();
                  final refId = st['refereeId'] as String?;
                  final refName = st['refereeName'] as String?;
                  final isMe = refId != null && refId == _refereeUid;
                  final isOccupiedByOther = refId != null && refId.isNotEmpty && !isMe;
                  final isUnassigned = refId == null || refId.isEmpty;
                  final scoreA = st['scoreA'] ?? 0;
                  final scoreB = st['scoreB'] ?? 0;
                  final teamA = st['teamA'] ?? 'الفريق أ';
                  final teamB = st['teamB'] ?? 'الفريق ب';

                  Color cardBorderColor;
                  if (isMe) {
                    cardBorderColor = Colors.greenAccent;
                  } else if (isOccupiedByOther) {
                    cardBorderColor = Colors.orangeAccent.withValues(alpha: 0.6);
                  } else {
                    cardBorderColor = AppTheme.primaryBlue;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorderColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('مباشر الآن 🔴', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            if (isMe)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 14, color: Colors.greenAccent),
                                    SizedBox(width: 4),
                                    Text('أنت الحكم المعين ⚖️', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            else if (isOccupiedByOther)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lock_rounded, size: 14, color: Colors.orangeAccent),
                                    const SizedBox(width: 4),
                                    Text('الحكم: $refName (مشغول)', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.radio_button_checked, size: 14, color: AppTheme.primaryBlue),
                                    SizedBox(width: 4),
                                    Text('شاغر (متاح للتحكيم) 🟢', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          stTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$teamA ($scoreA) vs ($scoreB) $teamB',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                        ),
                        const SizedBox(height: 10),

                        if (isMe) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MatchControlRoom(matchId: stId, initialData: st),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.tune_rounded, size: 16, color: Colors.black),
                                  label: const Text('إدارة وتحكيم البث ⚖️', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LiveMatchScreen(matchId: stId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.live_tv, size: 16, color: Colors.white),
                                label: const Text('عرض البث 💬', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        ] else if (isUnassigned) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _claimStream(st),
                                  icon: const Icon(Icons.gavel_rounded, size: 16, color: Colors.black),
                                  label: const Text('استلام تحكيم هذا البث ⚖️', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LiveMatchScreen(matchId: stId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
                                label: const Text('مشاهدة', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'يقوم الحكم "$refName" بتحكيم هذا البث حالياً. يمكنك تحكيم بث آخر شاغر.',
                                    style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LiveMatchScreen(matchId: stId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
                                label: const Text('مشاهدة 👁️', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'جميع مباريات البطولات والجدول 🏆',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getAllMatchesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
              }
              final matches = snapshot.data ?? [];
              if (matches.isEmpty) {
                return Center(
                  child: Text('لا توجد مباريات مسجلة حالياً', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                );
              }
              return Column(
                children: matches.map((match) {
                  final status = match['status'] ?? 'scheduled';
                  final isLive = status == 'live' || match['isLive'] == true;
                  final refName = match['refereeName'] as String?;

                  return Card(
                    color: Theme.of(context).colorScheme.surface,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLive ? Colors.red : Colors.blue.withValues(alpha: 0.2),
                        child: Icon(isLive ? Icons.live_tv : Icons.sports_score, color: isLive ? Colors.white : Colors.blue),
                      ),
                      title: Text('${match['teamA'] ?? 'فريق أ'} VS ${match['teamB'] ?? 'فريق ب'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('النتيجة: ${match['scoreA'] ?? 0} - ${match['scoreB'] ?? 0} | ${refName != null ? 'الحكم: $refName' : (match['time'] ?? 'مجدولة')}'),
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
                }).toList(),
              );
            },
          ),
        ],
      ),
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
