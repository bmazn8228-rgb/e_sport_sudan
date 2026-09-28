import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'submit_complaint_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  bool _isLoading = true;
  String _whatsappNumber = '+249123456789';
  String _telegramUsername = 'EsportSudanSupport';
  String _facebookUrl = 'https://facebook.com/EsportSudan';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await FirestoreService().getAppConfig();
      setState(() {
        _whatsappNumber = config['supportPhone'] ?? _whatsappNumber;
        _telegramUsername = config['telegramUsername'] ?? _telegramUsername;
        _facebookUrl = config['facebookUrl'] ?? _facebookUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يمكن فتح الرابط: $urlString')),
        );
      }
    }
  }

  void _openWhatsApp() {
    final cleanPhone = _whatsappNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final message = Uri.encodeComponent('مرحباً إدارة E-Sport Sudan، أحتاج إلى مساعدة بخصوص التطبيق.');
    _launchUrl('https://wa.me/$cleanPhone?text=$message');
  }

  void _openTelegram() {
    final username = _telegramUsername.replaceAll('@', '');
    _launchUrl('https://t.me/$username');
  }

  void _openFacebook() {
    _launchUrl(_facebookUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('مركز المساعدة والدعم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Section
                  Text(
                    'تواصل معنا مباشرة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ContactCard(
                          icon: Icons.chat_bubble_outline,
                          title: 'واتساب',
                          color: Colors.green,
                          onTap: _openWhatsApp,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ContactCard(
                          icon: Icons.send_outlined,
                          title: 'تيليجرام',
                          color: Colors.blueAccent,
                          onTap: _openTelegram,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ContactCard(
                          icon: Icons.facebook,
                          title: 'فيسبوك',
                          color: Colors.indigo,
                          onTap: _openFacebook,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),

                  // Submit Complaint Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.redAccent.withValues(alpha: 0.1), Colors.redAccent.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SubmitComplaintScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.report_problem_outlined, color: Colors.redAccent),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تقديم شكوى رسمية',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'غش، مشكلة مالية، أو مشكلة تقنية معقدة',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),

                  // FAQ Section
                  Text(
                    'الأسئلة الشائعة والقوانين',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildFaqItem(
                    context,
                    'كيف أشارك في البطولات؟',
                    'يجب أن تمتلك حساباً موثقاً ورصيداً كافياً في محفظتك، ثم التوجه لصفحة البطولات والضغط على "تسجيل" سواء كلاعب فردي أو مع فريقك.',
                  ),
                  _buildFaqItem(
                    context,
                    'متى يتم سحب الأرباح؟',
                    'تتم مراجعة طلبات سحب الأرباح ومعالجتها خلال 24-48 ساعة عمل كحد أقصى، وسيصلك إشعار فور التحويل.',
                  ),
                  _buildFaqItem(
                    context,
                    'ما هي قوانين مكافحة الغش؟',
                    'أي استخدام لبرامج مساعدة خارجية أو محاكيات غير مصرح بها يعرض حسابك والفريق بالكامل للحظر النهائي ومصادرة الجوائز.',
                  ),
                  _buildFaqItem(
                    context,
                    'كيف أثبت نتيجتي بعد المباراة؟',
                    'يجب على الكابتن تصوير شاشة النتيجة النهائية ورفعها في صفحة إدارة مباريات الفريق ليتم مراجعتها من قبل الحكم.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        collapsedIconColor: AppTheme.primaryBlue,
        iconColor: AppTheme.primaryBlue,
        childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 0),
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
