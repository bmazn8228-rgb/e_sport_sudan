import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

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
        title: const Text('لوحة تحكم الإدارة والصلاحيات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Role Badge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الدور الحالي المُحدد للتجربة:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeRole.displayNameArabic,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _activeRole.toValue().toUpperCase(),
                          style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('اختر دوراً لمعاينة صلاحياته والعمليات المسموحة له:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: UserRole.values.map((role) {
                      final isSelected = role == _activeRole;
                      return ChoiceChip(
                        label: Text(role.displayNameArabic, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: Colors.white10,
                        onSelected: (_) => setState(() => _activeRole = role),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // One-Click Database Seeding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.cloud_upload_outlined, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('تهيئة الجداول السحابية (One-Click Seed)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'زر بنقرة واحدة لإنشاء وتعبئة جميع الجداول تلقائياً في Firebase (البطولات، الفرق، إحصائيات PUBG و EA FC، وحسابات الأدمن).',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                      child: Text(_statusMessage!, style: const TextStyle(fontSize: 12, color: Colors.amberAccent)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSeeding ? null : _seedDatabase,
                      icon: _isSeeding
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.flash_on, color: Colors.black),
                      label: Text(
                        _isSeeding ? 'جاري تهيئة الجداول...' : 'إنشاء وتعبئة الجداول الآن 🚀',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Stream Broadcast Management Card
            _buildLiveStreamManagementCard(context),
            const SizedBox(height: 24),

            // Role-Specific Action Cards
            const Text('العمليات والصلاحيات المتاحة لهذا الدور:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),

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
          _buildActionCard('إدارة كافة الحسابات والأدوار', 'تحديد وتغيير رتب المستخدمين ومنح صلاحيات الأدمن', Icons.admin_panel_settings, Colors.purple),
          _buildActionCard('إدارة قواعد الأمان (Security Rules)', 'تطبيق سياسات Firestore والحماية الشاملة', Icons.security, Colors.blue),
          _buildActionCard('الوصول المالي والبطولات الكامل', 'صلاحيات مطلقة للتعديل والحذف لكافة الجداول', Icons.all_inclusive, AppTheme.primaryGreen),
        ];

      case UserRole.tournamentAdmin:
        return [
          _buildActionCard('إنشاء وإدارة البطولات', 'تحديد رسوم الاشتراك، الجوائز، والتواريخ في جدول tournaments', Icons.emoji_events, Colors.amber),
          _buildActionCard('اعتماد تسجيل الفرق', 'مراجعة طلبات الانضمام للبطولات وإنشاء شجرة المواجهات (Brackets)', Icons.groups, Colors.teal),
          _buildActionCard('تحديث إحصائيات الألعاب', 'تعديل جدول rankings و game_stats لكل لعبة بشكل منفصل', Icons.bar_chart, Colors.orange),
        ];

      case UserRole.referee:
        return [
          _buildActionCard('التحكم في نتائج المباريات المباشرة', 'تعديل النتيجة الحية وحالة المباراة (مباشر / انتهت)', Icons.sports_score, Colors.lightBlue),
          _buildActionCard('إدارة رابط البث المباشر (YouTube)', 'تحديث معرف أو رابط فيديو البث المباشر', Icons.live_tv, Colors.red),
          _buildActionCard('الإشراف على الدردشة المباشرة (Chat)', 'حظر المستخدمين المسيئين وحذف التعليقات المخالفة', Icons.chat_bubble_outline, Colors.pink),
        ];

      case UserRole.financeAdmin:
        return [
          _buildActionCard('مراجعة إشعارات التحويل (بنكك / فوري)', 'فحص صور الإشعارات في جدول transactions وقبولها', Icons.receipt_long, Colors.green),
          _buildActionCard('إيداع الأرصدة في محافظ اللاعبين', 'تحديث رصيد جدول wallets عند نجاح التحويل', Icons.account_balance_wallet, Colors.teal),
          _buildActionCard('صرف جوائز البطولات', 'تسليم الجوائز المالية للفائزين بعد انتهاء البطولة', Icons.payments, Colors.amber),
        ];

      case UserRole.player:
        return [
          _buildActionCard('إنشاء وإدارة الفريق الخاص', 'تعديل بيانات فريقه وإضافة اللاعبين واللوقو', Icons.group_add, Colors.blue),
          _buildActionCard('التسجيل في البطولات وشحن الرصيد', 'دفع الرسوم عبر المحفظة وإرفاق إشعار التحويل', Icons.sports_esports, AppTheme.primaryGreen),
          _buildActionCard('المشاركة في الدردشة وتصفح التصنيفات', 'متابعة البث الحي والتعليق ورؤية الترتيب العام', Icons.chat, Colors.cyan),
        ];
    }
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive ? Colors.redAccent.withOpacity(0.6) : Colors.white12,
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
                      Icon(Icons.live_tv, color: isLive ? Colors.redAccent : Colors.white70, size: 22),
                      const SizedBox(width: 8),
                      const Text('إدارة ونقل البث المباشر للمستخدمين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLive ? Colors.red : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: isLive ? Colors.white : Colors.white54, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          isLive ? 'نشط الآن 🔴' : 'متوقف',
                          style: TextStyle(
                            color: isLive ? Colors.white : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isLive && currentTitle.isNotEmpty) ...[
                Text('عنوان البث: $currentTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 4),
                Text('معرف الفيديو: $currentVideoId', style: const TextStyle(fontSize: 11, color: Colors.white54)),
                const SizedBox(height: 12),
              ] else ...[
                const Text(
                  'أدخل رابط أو كود بث YouTube Live ليتم عرضه فوراً لكافة مستخدمي التطبيق في الشاشة الرئيسية وتبويب المباريات.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
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
                      icon: const Icon(Icons.settings, color: Colors.black, size: 18),
                      label: Text(
                        isLive ? 'تعديل رابط البث 🎥' : 'بدء بث مباشر جديد 🎥',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (isLive) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmStopLiveStream(context),
                      icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 18),
                      label: const Text('إيقاف', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
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
                    const Row(
                      children: [
                        Icon(Icons.live_tv, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('ضبط وتحديث البث المباشر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('رابط البث من YouTube أو معرف الفيديو:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: https://www.youtube.com/watch?v=xxxx أو xxxx',
                    prefixIcon: Icon(Icons.link, color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('عنوان البث المباشر:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'مثال: نهائي بطولة السودان - الهلال ضد المريخ',
                    prefixIcon: Icon(Icons.title, color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.primaryGreen,
                  title: const Text('تفعيل البث وإظهاره للمستخدمين الآن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text('عند التفعيل سيظهر البث فوراً في الواجهة الرئيسية وتبويب المباريات', style: TextStyle(fontSize: 11, color: Colors.white54)),
                  value: isLive,
                  onChanged: (val) => setModalState(() => isLive = val),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final rawInput = urlController.text.trim();
                            if (rawInput.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('يرجى إدخال رابط أو معرف البث أولاً ⚠️'), backgroundColor: Colors.red),
                              );
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
                                  const SnackBar(
                                    content: Text('تم تحديث ونشر رابط البث المباشر للمستخدمين بنجاح ✅', style: TextStyle(color: Colors.black)),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('فشل تحديث رابط البث ❌'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.cloud_upload, color: Colors.black),
                    label: Text(isSaving ? 'جاري الحفظ...' : 'نشر وتحديث البث المباشر للمستخدمين 🚀', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
        backgroundColor: AppTheme.cardDark,
        title: const Text('إيقاف البث المباشر', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من رغبتك في إيقاف البث المباشر الحالي؟ سيظهر للمستخدمين أن البث متوقف.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirestoreService().stopLiveStream();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إيقاف البث المباشر بنجاح 🛑', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('فشل في إيقاف البث ❌'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('إيقاف البث'),
          ),
        ],
      ),
    );
  }
}
