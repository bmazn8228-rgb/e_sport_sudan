import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/widgets/animated_lottie_icon.dart';
import 'package:e_sport_sudan/features/team/presentation/screens/team_management_screen.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/referee_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/super_admin_dashboard.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';
import 'package:e_sport_sudan/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:e_sport_sudan/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:e_sport_sudan/features/profile/presentation/screens/settings_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isCardFlipped = false;
  UserModel? _userModel;
  bool _isLoading = true;
  bool _isImageUploading = false;

  int _totalMatches = 0;
  int _wins = 0;
  String _winRate = '0%';
  int _points = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final userModel = await FirestoreService().getUser(user.uid);
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _isLoading = false;
          });
          if (userModel?.teamId != null && userModel!.teamId!.isNotEmpty) {
            _loadTeamData(userModel.teamId!);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTeamData(String teamId) async {
    try {
      final teamData = await FirestoreService().getTeam(teamId);
      if (teamData != null && mounted) {
        setState(() {
          _points = teamData['points'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error implicitly
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    final role = _userModel?.role ?? UserRole.player;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'الملف الشخصي والبطاقة التنافسية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded, size: 20),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                
                if (confirm != true) return;

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
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. National Digital Player Card (Apple Wallet Flip Card)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _isCardFlipped = !_isCardFlipped);
              },
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: _isCardFlipped ? 180 : 0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (BuildContext context, double val, Widget? child) {
                  bool isFront = val < 90;
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(val * 3.1415926535897932 / 180),
                    alignment: Alignment.center,
                    child: isFront
                        ? _buildFrontCard()
                        : Transform(
                            transform: Matrix4.identity()..rotateY(3.1415926535897932),
                            alignment: Alignment.center,
                            child: _buildBackCard(),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // 2. iOS-Style Stats 3-Pillar Row
            _buildStatsRow(),
            const SizedBox(height: 20),
            
            // 3. Trophy Cabinet (Badges)
            _buildTrophyCabinet(),
            const SizedBox(height: 20),
            
            // 4. Match History
            if (_userModel?.teamId != null && _userModel!.teamId!.isNotEmpty)
              _buildMatchHistory(),
            const SizedBox(height: 20),

            // 5. Apple Inset Group: Financial Services
            _buildSectionHeader('الخدمات المالية'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildPortalTile(
                    title: 'محفظة اللاعب (المحفظة الإلكترونية)',
                    subtitle: 'إدارة الرصيد، الشحن عبر بنكك، وسحب الجوائز',
                    lottieAsset: 'assets/lottie/wallet.json',
                    color: AppTheme.primaryBlue,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. Apple Inset Group: Competitive Services
            _buildSectionHeader('الخدمات التنافسية'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildPortalTile(
                    title: 'إدارة الفريق والتشكيلة',
                    subtitle: 'يتوفر قريباً',
                    lottieAsset: 'assets/lottie/gamepad.json',
                    color: Colors.cyanAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamManagementScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. Administrative Portals (Based on Role)
            if (role != UserRole.player && role != UserRole.financeAdmin) ...[
              _buildSectionHeader('بوابات إدارة النظام والصلاحيات'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    if (role == UserRole.superAdmin || role == UserRole.tournamentAdmin) ...[
                      _buildPortalTile(
                        title: 'لوحة تحكم منظم البطولة',
                        subtitle: 'إدارة المجموعات والقرعة التلقائية وتحديث البيانات',
                        icon: Icons.admin_panel_settings_rounded,
                        color: Colors.orangeAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrganizerDashboard())),
                      ),
                      Divider(color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 64),
                    ],
                    if (role == UserRole.superAdmin || role == UserRole.referee) ...[
                      _buildPortalTile(
                        title: 'لوحة تحكم الحكم المعتمد',
                        subtitle: 'إدخال النتائج، إدارة البث، وتوثيق النزاهة',
                        icon: Icons.sports_rounded,
                        color: Colors.blueAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RefereeDashboard())),
                      ),
                      if (role == UserRole.superAdmin)
                        Divider(color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 64),
                    ],
                    if (role == UserRole.superAdmin) ...[
                      _buildPortalTile(
                        title: 'لوحة المشرف العام (Super Admin)',
                        subtitle: 'السيادة الوطنية واعتماد الرخص والحكام والفرق',
                        icon: Icons.security_rounded,
                        color: Colors.amber,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SuperAdminDashboard())),
                      ),
                      Divider(color: Colors.white.withValues(alpha: 0.06), height: 1, indent: 64),
                      _buildPortalTile(
                        title: 'إدارة الصلاحيات وقاعدة البيانات السحابية ☁️',
                        subtitle: 'فحص صلاحيات الأدوار وبث المباريات وتهيئة الجداول',
                        icon: Icons.cloud_sync_rounded,
                        color: AppTheme.primaryBlue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen())),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 8. Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm != true) return;

                  await AuthService().signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                label: const Text('تسجيل الخروج من الحساب', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.06),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;
    
    setState(() => _isImageUploading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _userModel == null) throw Exception('المستخدم غير مسجل');
      
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
      
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      await user.updatePhotoURL(downloadUrl);
      
      final updatedUserModel = UserModel(
        uid: _userModel!.uid,
        email: _userModel!.email,
        displayName: _userModel!.displayName,
        phone: _userModel!.phone,
        photoUrl: downloadUrl,
        gameId: _userModel!.gameId,
        role: _userModel!.role,
        teamId: _userModel!.teamId,
        settings: _userModel!.settings,
      );
      
      await FirestoreService().saveUser(updatedUserModel);
      
      if (mounted) {
        setState(() {
          _userModel = updatedUserModel;
          _isImageUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImageUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في رفع الصورة، حاول مرة أخرى.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildFrontCard() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '000000';
    final shortUid = uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase();
    final displayName = user?.displayName ?? 'لاعب إلكتروني';

    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Avatar + Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _isImageUploading ? null : _pickAndUploadImage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                        image: (_userModel?.photoUrl != null && _userModel!.photoUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(_userModel!.photoUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _isImageUploading
                          ? const Padding(
                              padding: EdgeInsets.all(14.0),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                            )
                          : (_userModel?.photoUrl == null || _userModel!.photoUrl!.isEmpty)
                              ? const Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 24)
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      const Text('فريق غير محدد', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('بطاقة الهوية الرقمية 🇸🇩', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('E-SPORT SUDAN', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),

          // Middle Row: Player ID & National Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('معرف اللاعب (Player ID)', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(height: 3),
                  Text(
                    'SD-$shortUid-SDN',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.1),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('التقييم الوطني', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  SizedBox(height: 3),
                  Text('يتوفر قريباً', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),

          // Bottom Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('المستوى: يتوفر قريباً', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('انقر للقلب 🔄 QR', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard() {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '000000';

    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: QrImageView(
                data: uid,
                version: QrVersions.auto,
                size: 105.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('رمز التحقق السريع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                SizedBox(height: 6),
                Text('امسح الرمز للتحقق من هوية اللاعب وصلاحية تسجيله في بطولات الاتحاد.', style: TextStyle(color: Colors.white54, fontSize: 10, height: 1.3)),
                SizedBox(height: 10),
                Text('معتمد رسمياً 🇸🇩', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                SizedBox(height: 2),
                Text('انقر للعودة للواجهة 🔄', style: TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStatPillar('المباريات', '$_totalMatches', Icons.sports_esports_rounded, AppTheme.primaryBlue),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.06)),
          Expanded(
            child: _buildMiniStatPillar('نسبة الفوز', _winRate, Icons.trending_up_rounded, Colors.orangeAccent),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.06)),
          Expanded(
            child: _buildMiniStatPillar('النقاط', '$_points', Icons.military_tech_rounded, Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatPillar(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildTrophyCabinet() {
    List<Widget> badges = [];

    if (_wins >= 1) {
      badges.add(_buildBadge('أول انتصار', 'assets/lottie/trophy.json', Colors.amber));
    }
    if (_wins >= 5) {
      badges.add(_buildBadge('المحارب', 'assets/lottie/gamepad.json', Colors.orange));
    }
    if (_totalMatches >= 10) {
      badges.add(_buildBadge('المخضرم', 'assets/lottie/trophy.json', Colors.purple));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('خزانة الإنجازات (Badges)'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: badges.isEmpty
              ? Column(
                  children: [
                    const AnimatedLottieIcon(lottieAsset: 'assets/lottie/trophy.json', width: 60, height: 60),
                    const SizedBox(height: 8),
                    const Text('لا توجد إنجازات بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 4),
                    const Text('العب مباريات وحقق انتصارات لفتح الشارات!', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
                  ],
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: badges,
                ),
        ),
      ],
    );
  }

  Widget _buildBadge(String title, String lottie, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: AnimatedLottieIcon(lottieAsset: lottie, width: 40, height: 40),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMatchHistory() {
    if (_userModel?.teamId == null || _userModel!.teamId!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('سجل المباريات (Match History)'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService().getTeamMatchesStream(_userModel!.teamId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
              }

              final matches = snapshot.data ?? [];
              
              if (matches.isNotEmpty && mounted) {
                // We shouldn't setState during build. Let's schedule it for next frame or just calculate locally if we only use it here.
                // Wait, _totalMatches and _winRate are in state.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  int total = matches.length;
                  int wins = 0;
                  for (var m in matches) {
                    bool isTeamA = m['teamAId'] == _userModel!.teamId || m['teamA'] == _userModel!.teamId;
                    if ((isTeamA && m['winner'] == 'teamA') || (!isTeamA && m['winner'] == 'teamB')) {
                      wins++;
                    }
                  }
                  if (_totalMatches != total || _wins != wins) {
                    setState(() {
                      _totalMatches = total;
                      _wins = wins;
                      _winRate = total > 0 ? '${((wins / total) * 100).toStringAsFixed(1)}%' : '0%';
                    });
                  }
                });
              }

              if (matches.isEmpty) {
                return Column(
                  children: [
                    const AnimatedLottieIcon(lottieAsset: 'assets/lottie/gamepad.json', width: 60, height: 60),
                    const SizedBox(height: 8),
                    const Text('لا توجد مباريات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 4),
                    const Text('لم يلعب فريقك أي مباريات بعد.', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
                  ],
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length > 5 ? 5 : matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final bool isTeamA = match['teamAId'] == _userModel!.teamId || match['teamA'] == _userModel!.teamId;
                  final String opponent = isTeamA ? (match['teamB'] ?? 'غير محدد') : (match['teamA'] ?? 'غير محدد');
                  final bool isWinner = (isTeamA && match['winner'] == 'teamA') || (!isTeamA && match['winner'] == 'teamB');
                  final int myScore = isTeamA ? (match['scoreA'] ?? 0) : (match['scoreB'] ?? 0);
                  final int opponentScore = isTeamA ? (match['scoreB'] ?? 0) : (match['scoreA'] ?? 0);
                  
                  String status = match['status'] ?? 'غير محدد';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isWinner ? AppTheme.primaryBlue.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(isWinner ? Icons.emoji_events : Icons.close, color: isWinner ? AppTheme.primaryBlue : Colors.red, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ضد $opponent', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(status, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '$myScore - $opponentScore',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isWinner ? AppTheme.primaryBlue : Colors.white,
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
      ],
    );
  }

  Widget _buildPortalTile({
    required String title,
    required String subtitle,
    IconData? icon,
    String? lottieAsset,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(lottieAsset != null ? 4 : 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: lottieAsset != null
                  ? AnimatedLottieIcon(lottieAsset: lottieAsset, width: 32, height: 32)
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, size: 20, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
