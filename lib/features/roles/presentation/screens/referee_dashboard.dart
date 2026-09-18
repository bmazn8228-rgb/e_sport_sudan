import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';

class RefereeDashboard extends StatefulWidget {
  const RefereeDashboard({Key? key}) : super(key: key);

  @override
  State<RefereeDashboard> createState() => _RefereeDashboardState();
}

class _RefereeDashboardState extends State<RefereeDashboard> {
  int _scoreA = 2;
  int _scoreB = 1;
  bool _screenshotUploaded = false;

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
              color: Colors.blue.withOpacity(0.2),
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
            // Supervised Match Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المباراة الموكلة للتحكيم #M1', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                        child: const Text('مباشر LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTeamScore('صقور النيل', _scoreA, (v) => setState(() => _scoreA = v)),
                      const Text('VS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white54)),
                      _buildTeamScore('فرسان المقرن', _scoreB, (v) => setState(() => _scoreB = v)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Referee Actions
            const Text('إجراءات توثيق النتيجة والنزاهة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Proof Screenshot Upload Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. رفع لقطة شاشة النتيجة النهائية (Match Screenshot)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('إلزامية لاعتماد النتيجة رسمياً من قبل محرك TME', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _screenshotUploaded = true);
                    },
                    icon: Icon(_screenshotUploaded ? Icons.check_circle : Icons.upload_file, color: _screenshotUploaded ? AppTheme.primaryGreen : Colors.white),
                    label: Text(_screenshotUploaded ? 'تم رفع لقطة الشاشة بنجاح' : 'اختيار صورة النتيجة من المعرض', style: TextStyle(color: _screenshotUploaded ? AppTheme.primaryGreen : Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _screenshotUploaded ? AppTheme.primaryGreen : Colors.white24),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Anti-cheat / Violations Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. تقرير المخالفات وسلوك اللعب النظيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('تسجيل أي حالة غش أو استخدام برامج غير مصرح بها أو عدم حضور', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.warning, color: Colors.orange, size: 16),
                          label: const Text('تسجيل إنذار', style: TextStyle(color: Colors.orange, fontSize: 12)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.block, color: Colors.red, size: 16),
                          label: const Text('إقصاء (Disqualify)', style: TextStyle(color: Colors.red, fontSize: 11)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Final Result
            ElevatedButton.icon(
              onPressed: _screenshotUploaded
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.primaryGreen,
                          content: Text('تم توثيق النتيجة وتحديث الشجرة وقواعد بيانات Firebase فوراً! ⚡', style: TextStyle(color: Colors.black)),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.verified_user),
              label: const Text('التوقيع الإلكتروني واعتماد النتيجة النهائية'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScore(String name, int score, ValueChanged<int> onScoreChange) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
              onPressed: score > 0 ? () => onScoreChange(score - 1) : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
              child: Text('$score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
              onPressed: () => onScoreChange(score + 1),
            ),
          ],
        ),
      ],
    );
  }
}
