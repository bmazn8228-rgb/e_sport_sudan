import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/tournament/presentation/screens/payment_failure_screen.dart';
import 'package:e_sport_sudan/core/utils/validators.dart';
import 'package:e_sport_sudan/core/utils/connectivity_helper.dart';

class TournamentRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> tournamentData;

  const TournamentRegistrationScreen({Key? key, required this.tournamentData}) : super(key: key);

  @override
  State<TournamentRegistrationScreen> createState() => _TournamentRegistrationScreenState();
}

class _TournamentRegistrationScreenState extends State<TournamentRegistrationScreen> {
  int _currentStep = 1; // 1 to 5
  final _teamNameController = TextEditingController(text: 'صقور النيل (Nile Falcons)');
  final _leaderIgnController = TextEditingController(text: 'Falcon_Leader');
  final _transactionIdController = TextEditingController();
  final _playerIdController = TextEditingController();
  
  String _selectedPaymentMethod = 'بنكك (Bankak - بنك الخرطوم)';
  String? _receiptFileName;
  String? _teamLogoFileName;

  final List<Map<String, dynamic>> _teamMembers = [
    {
      'id': 'SD-PRO-001',
      'name': 'أحمد عثمان علي',
      'ign': 'Falcon_Leader',
      'role': 'القائد (Assault)',
      'isLeader': true,
    }
  ];

  void _nextStep() async {
    if (_currentStep < 5) {
      if (_currentStep == 1) {
        String? teamNameError = Validators.validateName(_teamNameController.text, fieldName: 'اسم الفريق');
        String? ignError = Validators.validateName(_leaderIgnController.text, fieldName: 'الاسم داخل اللعبة للقائد');
        if (teamNameError != null || ignError != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(teamNameError ?? ignError!),
            backgroundColor: Colors.red,
          ));
          return;
        }
      }
      if (_currentStep == 2) {
        final requiredPlayers = widget.tournamentData['playersPerTeam'] ?? 1;
        if (_teamMembers.length != requiredPlayers) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('يجب أن يكون عدد أعضاء الفريق بالضبط $requiredPlayers لاعبين (بما فيهم القائد)'),
            backgroundColor: Colors.red,
          ));
          return;
        }
      }
      if (_currentStep == 4) {
        if (!await ConnectivityHelper.hasInternetConnection()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        if (_selectedPaymentMethod == 'المحفظة الإلكترونية (الرصيد المتاح)') {
          // Simulate a balance check. Required: 25000, Available: 15000 (Mocked to fail for demonstration)
          const double requiredAmount = 25000.0;
          const double availableBalance = 15000.0;
          
          if (availableBalance < requiredAmount) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentFailureScreen(
                  requiredAmount: requiredAmount,
                  availableBalance: availableBalance,
                ),
              ),
            );
            return; // Don't proceed to step 5
          }
        }
      }
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تسجيل البطولة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.tournamentData['title'] ?? 'بدون اسم', style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stepper indicator
            _buildStepper(),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.cardDark,
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 1 && _currentStep < 5) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('السابق', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        _currentStep == 5
                            ? 'العودة للرئيسية'
                            : _currentStep == 4
                                ? 'تأكيد الحوالة والتسجيل'
                                : 'المتابعة للخطوة التالية',
                      ),
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

  Widget _buildStepper() {
    final steps = ['البيانات', 'الفريق', 'المراجعة', 'الدفع', 'التأكيد'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الخطوة $_currentStep من 5',
                style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                steps[_currentStep - 1],
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              final stepNum = index + 1;
              final isDone = stepNum < _currentStep;
              final isActive = stepNum == _currentStep;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone || isActive ? AppTheme.primaryGreen : Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive
                        ? [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.5), blurRadius: 4)]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox();
    }
  }

  // Step 1: Data & Eligibility
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('شروط الأهلية واللوائح', 'يجب أن يكون جميع أفراد الفريق مقيمين في السودان أو حاملين للجنسية السودانية مع حسابات ألعاب غير محظورة.'),
        const SizedBox(height: 20),
        const Text('اسم الفريق التنافسي (Team Name)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(controller: _teamNameController, decoration: const InputDecoration(prefixIcon: Icon(Icons.shield))),
        const SizedBox(height: 16),
        const Text('شعار الفريق (Team Logo) - سيظهر في المنافسات', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            // Simulate picking an image
            setState(() {
              _teamLogoFileName = 'team_logo_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.png';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إرفاق شعار الفريق بنجاح ✔️')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _teamLogoFileName != null ? AppTheme.primaryGreen : Colors.white24,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _teamLogoFileName != null ? Icons.check_circle : Icons.image,
                  color: _teamLogoFileName != null ? AppTheme.primaryGreen : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _teamLogoFileName ?? 'اضغط هنا لرفع صورة شعار الفريق',
                    style: TextStyle(
                      color: _teamLogoFileName != null ? AppTheme.primaryGreen : Colors.white70,
                      fontWeight: _teamLogoFileName != null ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('اسم قائد الفريق في اللعبة (Leader IGN)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(controller: _leaderIgnController, decoration: const InputDecoration(prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 16),
        const Text('البريد الإلكتروني المعتمد للتواصل الرسمي', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const TextField(
          decoration: InputDecoration(
            hintText: 'contact@team.sd',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
      ],
    );
  }

  // Step 2: Lineup selection
  Widget _buildStep2() {
    final requiredPlayers = widget.tournamentData['playersPerTeam'] ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('تشكيلة اللاعبين المعتمدة', 'يجب أن تملك بطاقة لاعب رقمية معتمدة لكل عضو. القائد مضاف تلقائياً. البطولة تتطلب بالضبط $requiredPlayers لاعبين للفريق الواحد.'),
        const SizedBox(height: 16),
        
        // Add Player via ID
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _playerIdController,
                decoration: const InputDecoration(
                  hintText: 'أدخل معرف اللاعب (مثال: SD-PRO-123)',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                if (_playerIdController.text.isEmpty) return;
                final requiredPlayers = widget.tournamentData['playersPerTeam'] ?? 1;
                if (_teamMembers.length >= requiredPlayers) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الوصول للحد الأقصى وهو $requiredPlayers لاعبين')));
                   return;
                }
                
                // Simulate fetching player by ID
                setState(() {
                  _teamMembers.add({
                    'id': _playerIdController.text,
                    'name': 'لاعب جديد ${_teamMembers.length}',
                    'ign': 'PlayerIGN_${_teamMembers.length}',
                    'role': 'Assault',
                    'isLeader': false,
                  });
                  _playerIdController.clear();
                });
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة اللاعب بنجاح ✔️')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        const Text('أعضاء الفريق الحاليين:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        
        ..._teamMembers.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> player = entry.value;
          return _buildPlayerSlot(index, player);
        }),
      ],
    );
  }

  // Step 3: Review & Rules
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('مراجعة البيانات قبل السداد', 'يرجى التأكد من دقة بيانات اللاعبين ومعرفاتهم لتفادي الإقصاء أثناء فحص الغش ونزاهة المباريات.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildSummaryRow('البطولة:', widget.tournamentData['title'] ?? ''),
              const Divider(color: Colors.white10),
              _buildSummaryRow('الفريق:', _teamNameController.text),
              const Divider(color: Colors.white10),
              _buildSummaryRow('عدد اللاعبين:', '${_teamMembers.length} لاعبين (معتمدين)'),
              const Divider(color: Colors.white10),
              _buildSummaryRow('رسوم التسجيل:', '${widget.tournamentData['entryFee'] ?? 0} ج.س (رسوم تنظيم)'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(value: true, onChanged: (v) {}, activeColor: AppTheme.primaryGreen),
            const Expanded(
              child: Text(
                'أقر أنا قائد الفريق بالالتزام بجميع القوانين واللوائح الصادرة من الاتحاد السوداني للرياضات الإلكترونية.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 4: Payment
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('طريقة الدفع وسداد الرسوم', 'قم بالتحويل إلى حساب الاتحاد السوداني للرياضات الإلكترونية وأدخل رقم الإشعار أو المعاملة أدناه.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.4)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('حساب بنك الخرطوم (بنكك)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  Icon(Icons.account_balance, color: Colors.orange),
                ],
              ),
              SizedBox(height: 8),
              Text('رقم الحساب: 2459812', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('الاسم: الاتحاد السوداني للرياضات الإلكترونية', style: TextStyle(fontSize: 12, color: Colors.white70)),
              SizedBox(height: 4),
              Text('المبلغ المطلوب: 10,000 جنيه سوداني', style: TextStyle(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('طريقة التحويل المستخدمة', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedPaymentMethod,
          items: [
            'المحفظة الإلكترونية (الرصيد المتاح)',
            'بنكك (Bankak - بنك الخرطوم)',
            'فوري (Fawry - بنك فيصل)',
            'أوكاش (O-Kash)',
            'سايبر باي (SyberPay)',
          ].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.payment)),
        ),
        const SizedBox(height: 16),
        if (_selectedPaymentMethod == 'المحفظة الإلكترونية (الرصيد المتاح)') ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('سيتم خصم المبلغ من رصيد المحفظة', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('تأكد من وجود رصيد كافٍ قبل المتابعة.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const Text('رقم الإشعار / العملية (Transaction ID)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _transactionIdController,
            decoration: const InputDecoration(
              hintText: 'أدخل رقم المعاملة من تطبيق بنكك',
              prefixIcon: Icon(Icons.receipt_long),
            ),
          ),
          const SizedBox(height: 16),
          const Text('إرفاق صورة الإشعار (اختياري / مستحسن)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              // Simulate picking an image
              setState(() {
                _receiptFileName = 'receipt_bankak_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.jpg';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرفاق الإشعار بنجاح ✔️')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _receiptFileName != null ? AppTheme.primaryGreen : Colors.white24,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _receiptFileName != null ? Icons.check_circle : Icons.upload_file,
                    color: _receiptFileName != null ? AppTheme.primaryGreen : Colors.white70,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _receiptFileName ?? 'اضغط هنا لرفع صورة إشعار التحويل',
                      style: TextStyle(
                        color: _receiptFileName != null ? AppTheme.primaryGreen : Colors.white70,
                        fontWeight: _receiptFileName != null ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Step 5: Digital Pass
  Widget _buildStep5() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 48, color: Colors.black),
        ),
        const SizedBox(height: 16),
        const Text(
          'تم تأكيد التسجيل بنجاح! 🎉',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'تم إصدار بطاقة الدخول والمشاركة الرسمية للفريق في البطولة.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Digital Ticket Pass
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryGreen),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('بطاقة مشاركة معتمدة', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                    child: const Text('SD-E-PASS', style: TextStyle(fontSize: 10, letterSpacing: 1)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.tournamentTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'الفريق: ${_teamNameController.text}',
                style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // QR Code Graphic placeholder
              Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 120, color: Colors.black),
                ),
              ),
              const SizedBox(height: 12),
              const Text('رمز التحقق الخاص بالحكام والمنظمين', style: TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(int index, Map<String, dynamic> player) {
    bool isLeader = player['isLeader'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isLeader ? AppTheme.primaryGreen.withOpacity(0.5) : Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  isLeader ? Icons.star : Icons.person,
                  color: isLeader ? Colors.orange : AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${player['ign']} (${player['name']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      if (isLeader)
                        Text(player['role'], style: const TextStyle(color: Colors.white54, fontSize: 11))
                      else
                        SizedBox(
                          height: 24,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: player['role'],
                              dropdownColor: AppTheme.cardDark,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                              items: ['Assault', 'Sniper', 'Support', 'Fragger', 'احتياطي']
                                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                                  .toList(),
                              onChanged: (newRole) {
                                if (newRole != null) {
                                  setState(() {
                                    _teamMembers[index]['role'] = newRole;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isLeader)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              onPressed: () {
                setState(() {
                  _teamMembers.removeAt(index);
                });
              },
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _leaderIgnController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }
}
