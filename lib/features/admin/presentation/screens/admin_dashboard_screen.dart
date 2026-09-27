import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/super_admin_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/organizer_dashboard.dart';
import 'package:e_sport_sudan/features/roles/presentation/screens/referee_dashboard.dart';
import 'deposit_requests_screen.dart';
import 'tournament_admin_dashboard_screen.dart';
import 'referee_dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  UserRole _activeRole = UserRole.superAdmin;
  bool _isSeeding = false;
  String? _statusMessage;

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = null;
    });

    try {
      await FirestoreService().seedInitialData();
      setState(() {
        _isSeeding = false;
        _statusMessage = 'تمت تهيئة الجداول وحسابات الأدمن والبيانات الأولية بنجاح! ✅';
      });
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _statusMessage = 'تنبيه: يتطلب الاتصال المباشر بـ Firebase وجود ملف google-services.json الحقيقي.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('لوحة تحكم الإدارة والصلاحيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Role Badge Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الدور الحالي المُحدد للتجربة:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12)),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeRole.displayNameArabic,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _activeRole.toValue().toUpperCase(),
                          style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('اختر دوراً لمعاينة صلاحياته والعمليات المسموحة له:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: UserRole.values.map((role) {
                      final isSelected = role == _activeRole;
                      return ChoiceChip(
                        label: Text(role.displayNameArabic, style: TextStyle(color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface, fontSize: 11)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryBlue,
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                        onSelected: (_) => setState(() => _activeRole = role),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // One-Click Database Seeding
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('تهيئة الجداول السحابية (One-Click Seed)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'زر بنقرة واحدة لإنشاء وتعبئة جميع الجداول تلقائياً في Firebase (البطولات، الفرق، إحصائيات PUBG و EA FC، وحسابات الأدمن).',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  if (_statusMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: Text(_statusMessage!, style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
                    ),
                    SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _seedDatabase,
                      icon: _isSeeding
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Icon(Icons.flash_on, color: Colors.black),
                      label: Text(
                        _isSeeding ? 'جاري تهيئة الجداول...' : 'إنشاء وتعبئة الجداول الآن 🚀',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Live Stream Broadcast Management Card
            _buildLiveStreamManagementCard(context),
            SizedBox(height: 24),

            // Role-Specific Action Cards
            Text('العمليات والصلاحيات المتاحة لهذا الدور:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            SizedBox(height: 12),

            ..._buildRoleActions(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoleActions() {
    switch (_activeRole) {
      case UserRole.superAdmin:
        return [
          _buildActionCard(
            'إدارة كافة الحسابات والأدوار',
            'تحديد وتغيير رتب المستخدمين ومنح صلاحيات الأدمن في Firebase',
            Icons.admin_panel_settings,
            Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SuperAdminDashboard())),
          ),
          _buildActionCard(
            'مراجعة طلبات شحن الرصيد',
            'اعتماد إشعارات الدفع والتحويلات المالية للمحافظ',
            Icons.account_balance,
            Colors.greenAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DepositRequestsScreen())),
          ),
          _buildActionCard(
            'الوصول الشامل للبطولات والمواجهات',
            'إنشاء وتعديل وحذف البطولات وجداول المباريات',
            Icons.emoji_events,
            Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentAdminDashboardScreen())),
          ),
        ];

      case UserRole.tournamentAdmin:
        return [
          _buildActionCard(
            'إنشاء وإدارة البطولات',
            'تحديد رسوم الاشتراك، الجوائز، والتواريخ في جدول tournaments',
            Icons.emoji_events,
            Colors.amber,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TournamentAdminDashboardScreen())),
          ),
          _buildActionCard(
            'لوحة تحكم منظم البطولة والقرعة',
            'توليد القرعة التلقائية وتوزيع المجموعات وجدولة المباريات',
            Icons.dashboard_customize,
            Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerDashboard())),
          ),
          _buildActionCard(
            'إدارة الفرق والتشكيلات',
            'مراجعة الفرق المعتمدة وحذف أو تعديل بيانات الفرق',
            Icons.groups,
            Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizerDashboard())),
          ),
        ];

      case UserRole.referee:
        return [
          _buildActionCard(
            'لوحة تحكم الحكم المعتمد',
            'توثيق نتائج المباريات ورفع لقطات الشاشة المعتمدة',
            Icons.sports_score,
            Colors.lightBlue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RefereeDashboard())),
          ),
          _buildActionCard(
            'غرفة التحكم المباشر (كافة المباريات)',
            'تعديل النتيجة الحية وتوقيت المباراة أثناء اللعب',
            Icons.tune,
            Colors.blueAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RefereeDashboardScreen())),
          ),
          _buildActionCard(
            'إدارة رابط البث المباشر (YouTube)',
            'تحديث وتوجيه بث الفيديو المباشر للمستخدمين',
            Icons.live_tv,
            Colors.red,
            onTap: () => _showLiveStreamDialog(context),
          ),
        ];

      case UserRole.financeAdmin:
        return [
          _buildActionCard(
            'مراجعة إشعارات التحويل (بنكك / فوري)',
            'فحص صور الإشعارات في جدول transactions وقبولها',
            Icons.receipt_long,
            Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DepositRequestsScreen())),
          ),
          _buildActionCard(
            'إيداع الأرصدة في محافظ اللاعبين',
            'تحديث رصيد جدول wallets عند نجاح التحويل',
            Icons.account_balance_wallet,
            Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DepositRequestsScreen())),
          ),
        ];

      case UserRole.player:
        return [
          _buildActionCard(
            'محفظة اللاعب والشحن',
            'إرسال إشعارات التحويل وشحن الرصيد عبر بنكك',
            Icons.account_balance_wallet,
            AppTheme.primaryBlue,
          ),
          _buildActionCard(
            'التسجيل في البطولات الرسمية',
            'دفع الرسوم عبر المحفظة والاشتراك في البطولات المفتوحة',
            Icons.sports_esports,
            Colors.amber,
          ),
        ];
    }
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 3),
                      Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11)),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStreamManagementCard(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService().getGlobalLiveStream(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final isLive = data != null && data['isLive'] == true;
        final currentVideoId = (data?['youtubeVideoId'] ?? '').toString();
        final currentTitle = (data?['title'] ?? '').toString();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive ? Colors.redAccent.withOpacity(0.6) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
              width: isLive ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.live_tv, color: isLive ? Colors.redAccent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 22),
                      SizedBox(width: 8),
                      Text('إدارة ونقل البث المباشر للمستخدمين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLive ? Colors.red : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: isLive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 8),
                        SizedBox(width: 4),
                        Text(
                          isLive ? 'نشط الآن 🔴' : 'متوقف',
                          style: TextStyle(
                            color: isLive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (isLive && currentTitle.isNotEmpty) ...[
                Text('عنوان البث: $currentTitle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 4),
                Text('معرف الفيديو: $currentVideoId', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                SizedBox(height: 12),
              ] else ...[
                Text(
                  'أدخل رابط أو كود بث YouTube Live ليتم عرضه فوراً لكافة مستخدمي التطبيق في الشاشة الرئيسية وتبويب المباريات.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                ),
                SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showLiveStreamDialog(
                        context,
                        currentUrl: currentVideoId.isNotEmpty ? 'https://www.youtube.com/watch?v=$currentVideoId' : '',
                        currentTitle: currentTitle.isNotEmpty ? currentTitle : 'البث المباشر لمنافسات اليوم',
                        currentIsLive: isLive,
                      ),
                      icon: Icon(Icons.settings, color: Colors.black, size: 18),
                      label: Text(
                        isLive ? 'تعديل رابط البث 🎥' : 'بدء بث مباشر جديد 🎥',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (isLive) ...[
                    SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmStopLiveStream(context),
                      icon: Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 18),
                      label: Text('إيقاف', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLiveStreamDialog(BuildContext context, {String? currentUrl, String? currentTitle, bool currentIsLive = true}) {
    final urlController = TextEditingController(text: currentUrl ?? '');
    final titleController = TextEditingController(text: currentTitle ?? 'البث المباشر لمنافسات اليوم');
    bool isLive = currentIsLive;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.live_tv, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('ضبط وتحديث البث المباشر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text('رابط البث من YouTube أو معرف الفيديو:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                SizedBox(height: 6),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    hintText: 'مثال: https://www.youtube.com/watch?v=xxxx أو xxxx',
                    prefixIcon: Icon(Icons.link, color: Colors.redAccent),
                  ),
                ),
                SizedBox(height: 14),
                Text('عنوان البث المباشر:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'مثال: نهائي بطولة السودان - الهلال ضد المريخ',
                    prefixIcon: Icon(Icons.title, color: AppTheme.primaryBlue),
                  ),
                ),
                SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppTheme.primaryBlue,
                  title: Text('تفعيل البث وإظهاره للمستخدمين الآن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text('عند التفعيل سيظهر البث فوراً في الواجهة الرئيسية وتبويب المباريات', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
                  value: isLive,
                  onChanged: (val) => setModalState(() => isLive = val),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final rawInput = urlController.text.trim();
                            if (rawInput.isEmpty) {
                              NotificationService.showCustomToast(context, title: 'تنبيه النظام', message: 'يرجى إدخال رابط أو معرف البث أولاً ⚠️', type: ToastType.urgent);
                              return;
                            }

                            final videoId = YoutubePlayer.convertUrlToId(rawInput) ?? rawInput;

                            setModalState(() => isSaving = true);
                            try {
                              await FirestoreService().updateLiveStream(
                                youtubeVideoId: videoId,
                                title: titleController.text.trim().isEmpty ? 'البث المباشر' : titleController.text.trim(),
                                isLive: isLive,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم تحديث ونشر رابط البث المباشر للمستخدمين بنجاح ✅', style: TextStyle(color: Colors.black)),
                                    backgroundColor: AppTheme.primaryBlue,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                NotificationService.showCustomToast(context, title: 'تنبيه النظام', message: 'فشل تحديث رابط البث ❌', type: ToastType.urgent);
                              }
                            }
                          },
                    icon: isSaving
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Icon(Icons.cloud_upload, color: Colors.black),
                    label: Text(isSaving ? 'جاري الحفظ...' : 'نشر وتحديث البث المباشر للمستخدمين 🚀', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmStopLiveStream(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('إيقاف البث المباشر', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('هل أنت متأكد من رغبتك في إيقاف البث المباشر الحالي؟ سيظهر للمستخدمين أن البث متوقف.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().stopLiveStream();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إيقاف البث المباشر بنجاح 🛑', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  NotificationService.showCustomToast(context, title: 'تنبيه النظام', message: 'فشل في إيقاف البث ❌', type: ToastType.urgent);
                }
              }
            },
            child: Text('إيقاف البث'),
          ),
        ],
      ),
    );
  }
}
