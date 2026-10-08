import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Deposit State
  bool _isAddingFunds = false;
  bool _isUploadingReceipt = false;
  String _selectedPaymentMethod = 'بنك الخرطوم (تطبيق بنكك - Bankak)';
  final _transactionIdController = TextEditingController();
  final _amountController = TextEditingController();
  File? _receiptFile;
  String? _receiptFileName;

  // Withdrawal State
  bool _isWithdrawing = false;
  bool _isSubmittingWithdrawal = false;
  String _selectedWithdrawBank = 'بنك الخرطوم (تطبيق بنكك - Bankak)';
  final _withdrawAmountController = TextEditingController();
  final _withdrawAccountNumberController = TextEditingController();
  final _withdrawAccountHolderController = TextEditingController();
  double _currentBalance = 0.0;

  final List<String> _sudaneseBanks = [
    'بنك الخرطوم (تطبيق بنكك - Bankak)',
    'بنك فيصل الإسلامي (تطبيق فوري - Fawry)',
    'بنك أم درمان الوطني (تطبيق أوكاش - O-Kash)',
    'بنك النيل (تطبيق النيل بلس - NilePlus)',
    'محفظة كاشي الإلكترونية (Cashi)',
    'بنك العمال الوطني (تطبيق إشراقة)',
    'بنك البركة السوداني (البركة بلس)',
    'بنك التضامن الإسلامي (تضامن بلس)',
    'مصرف المزارع التجاري (مزارع بلس)',
    'بنك المال المتحد (U-Pay)',
    'بنك الجزيرة السوداني الأردني',
    'بنك الثروة الحيوانية',
    'بنك النيلين',
    'تطبيق بيللي (Pelly) / براڤو',
    'حساب بنكي سوداني آخر',
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // Trigger real-time UI rebuilds as user types the withdrawal amount
    _withdrawAmountController.addListener(() {
      if (mounted) setState(() {});
    });
    _withdrawAccountNumberController.addListener(() {
      if (mounted) setState(() {});
    });
    _withdrawAccountHolderController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _amountController.dispose();
    _withdrawAmountController.dispose();
    _withdrawAccountNumberController.dispose();
    _withdrawAccountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('المحفظة الإلكترونية', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryRed.withValues(alpha: 0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<double>(
                    stream: _firestoreService.getUserWalletStream(_userId),
                    builder: (context, snapshot) {
                      _currentBalance = snapshot.data ?? 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الرصيد المتاح في المحفظة',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                                  fontSize: 14,
                                ),
                              ),
                              Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 20),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${_currentBalance.toStringAsFixed(2)} ج.س',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 24),
                  if (!_isAddingFunds && !_isWithdrawing)
                    Row(
                      children: [
                        // Deposit Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isAddingFunds = true;
                                _isWithdrawing = false;
                              });
                            },
                            icon: Icon(Icons.add_circle_outline, color: Colors.black, size: 20),
                            label: Text('إيداع وشحن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              minimumSize: Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Withdrawal Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isWithdrawing = true;
                                _isAddingFunds = false;
                              });
                            },
                            icon: Icon(Icons.outbox_rounded, color: Colors.white, size: 20),
                            label: Text('سحب رصيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                              minimumSize: Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Deposit Form
            if (_isAddingFunds) ...[
              SizedBox(height: 24),
              _buildDepositForm(context),
            ],

            // Withdrawal Form
            if (_isWithdrawing) ...[
              SizedBox(height: 24),
              _buildWithdrawalForm(context),
            ],

            SizedBox(height: 32),

            Text('سجل العمليات المالية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            // Transactions List
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. Withdrawal Form Component
  // =========================================================================
  Widget _buildWithdrawalForm(BuildContext context) {
    final enteredAmountText = _withdrawAmountController.text.trim();
    final enteredAmount = double.tryParse(enteredAmountText) ?? 0.0;
    final hasEnteredAmount = enteredAmountText.isNotEmpty;
    final isAmountExceedingBalance = enteredAmount > _currentBalance;
    final isAmountValid = hasEnteredAmount && enteredAmount > 0 && !isAmountExceedingBalance;

    final isAccountNumProvided = _withdrawAccountNumberController.text.trim().isNotEmpty;
    final isAccountHolderProvided = _withdrawAccountHolderController.text.trim().isNotEmpty;
    final canSubmit = isAmountValid && isAccountNumProvided && isAccountHolderProvided && !_isSubmittingWithdrawal;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAmountExceedingBalance ? Colors.red : Colors.orangeAccent.withValues(alpha: 0.5),
          width: isAmountExceedingBalance ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAmountExceedingBalance ? Colors.red : Colors.orangeAccent).withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.outbox_rounded, color: Colors.orangeAccent, size: 20),
                  ),
                  SizedBox(width: 10),
                  Text('طلب سحب رصيد (تحويل بنكي)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 20),
                onPressed: () {
                  setState(() {
                    _isWithdrawing = false;
                    _withdrawAmountController.clear();
                    _withdrawAccountNumberController.clear();
                    _withdrawAccountHolderController.clear();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),

          // Sudanese Bank Selection
          Text('اختر البنك أو المحفظة الإلكترونية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedWithdrawBank,
            dropdownColor: Theme.of(context).colorScheme.surface,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.account_balance, color: AppTheme.primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _sudaneseBanks
                .map((bank) => DropdownMenuItem(
                      value: bank,
                      child: Text(bank, style: TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedWithdrawBank = value);
            },
          ),
          SizedBox(height: 16),

          // Amount Field with Real-Time Balance Validation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المبلغ المراد سحبه (ج.س)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              InkWell(
                onTap: () {
                  if (_currentBalance > 0) {
                    _withdrawAmountController.text = _currentBalance.toStringAsFixed(0);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'سحب كامل الرصيد (${_currentBalance.toStringAsFixed(0)} ج.س)',
                    style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: _withdrawAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'مثال: 5000',
              prefixIcon: Icon(Icons.payments_outlined, color: isAmountExceedingBalance ? Colors.red : AppTheme.primaryBlue),
              suffixText: 'ج.س',
              suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isAmountExceedingBalance ? Colors.red : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                  width: isAmountExceedingBalance ? 1.8 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isAmountExceedingBalance ? Colors.red : AppTheme.primaryBlue,
                  width: 2.0,
                ),
              ),
            ),
          ),

          // Active Notification/Warning Banner for Exceeding Balance
          if (hasEnteredAmount && isAmountExceedingBalance) ...[
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ تنبيه: المبلغ المطلوب أكبر من الرصيد المتاح!',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'المبلغ المطلوب (${enteredAmount.toStringAsFixed(2)} ج.س) يتجاوز رصيدك الحالي (${_currentBalance.toStringAsFixed(2)} ج.س). يرجى تصحيح المبلغ للمتابعة.',
                          style: TextStyle(color: Colors.red[300], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasEnteredAmount && enteredAmount <= 0) ...[
            SizedBox(height: 8),
            Text(
              '⚠️ يرجى إدخال مبلغ صحيح أكبر من الصفر',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ] else if (isAmountValid) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'المبلغ متاح. الرصيد المتبقي بعد السحب: ${(_currentBalance - enteredAmount).toStringAsFixed(2)} ج.س',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16),

          // Account Number or Mobile
          Text('رقم الحساب البنكي أو رقم الموبايل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 8),
          TextField(
            controller: _withdrawAccountNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'رقم حسابك في بنكك أو فوري أو المحفظة',
              prefixIcon: Icon(Icons.numbers_rounded, color: AppTheme.primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),

          // Account Holder Full Name
          Text('اسم صاحب الحساب (ثلاثي أو رباعي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 8),
          TextField(
            controller: _withdrawAccountHolderController,
            decoration: InputDecoration(
              hintText: 'اسم المستفيد كما هو مسجل في البنك',
              prefixIcon: Icon(Icons.person_pin_rounded, color: AppTheme.primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),

          // Info box
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سيصل طلب السحب للمسؤول المالي لمراجعته، وفور إيداع المبلغ في حسابك البنكي ستتلقى إشعاراً فورياً بتأكيد العملية.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Submit Withdrawal Button
          ElevatedButton(
            onPressed: canSubmit ? () => _confirmAndSubmitWithdrawal(context, enteredAmount) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAmountExceedingBalance ? Colors.grey : Colors.orangeAccent,
              disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmittingWithdrawal
                ? CircularProgressIndicator(color: Colors.black)
                : Text(
                    isAmountExceedingBalance
                        ? 'المبلغ يتجاوز الرصيد المتاح ⚠️'
                        : 'تأكيد وإرسال طلب السحب',
                    style: TextStyle(
                      color: canSubmit ? Colors.black : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmAndSubmitWithdrawal(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.outbox_rounded, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text('تأكيد طلب السحب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من تفاصيل طلب السحب؟', style: TextStyle(fontSize: 14)),
            SizedBox(height: 14),
            _buildDetailRow('المبلغ المطلوب:', '${amount.toStringAsFixed(2)} ج.س'),
            _buildDetailRow('البنك / المحفظة:', _selectedWithdrawBank),
            _buildDetailRow('رقم الحساب:', _withdrawAccountNumberController.text.trim()),
            _buildDetailRow('اسم صاحب الحساب:', _withdrawAccountHolderController.text.trim()),
            SizedBox(height: 10),
            Text(
              '⚠️ سيتم حجز المبلغ من رصيدك فوراً ريثما يقوم المسؤول بالتحويل وإشعارك.',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('تراجع', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _executeWithdrawal(amount);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: Text('تأكيد السحب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _executeWithdrawal(double amount) async {
    setState(() => _isSubmittingWithdrawal = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _firestoreService.submitWithdrawalRequest(
        userId: _userId,
        amount: amount,
        bankAccountName: _selectedWithdrawBank,
        accountNumber: _withdrawAccountNumberController.text.trim(),
        accountHolderName: _withdrawAccountHolderController.text.trim(),
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم إرسال طلب السحب بنجاح! سيتم إيداع المبلغ في حسابك البنكي بعد مراجعة المسؤول ✅',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 4),
        ),
      );

      setState(() {
        _isWithdrawing = false;
        _isSubmittingWithdrawal = false;
        _withdrawAmountController.clear();
        _withdrawAccountNumberController.clear();
        _withdrawAccountHolderController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingWithdrawal = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء إرسال طلب السحب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================================
  // 2. Deposit Form Component
  // =========================================================================
  Widget _buildDepositForm(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('طلب إضافة رصيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 20),
                onPressed: () {
                  setState(() {
                    _isAddingFunds = false;
                    _receiptFileName = null;
                    _transactionIdController.clear();
                    _amountController.clear();
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('اختر طريقة التحويل', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedPaymentMethod,
            dropdownColor: Theme.of(context).colorScheme.surface,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.account_balance),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _sudaneseBanks
                .map((method) => DropdownMenuItem(
                      value: method,
                      child: Text(method, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedPaymentMethod = value);
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'أدخل قيمة الرصيد (ج.س)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _transactionIdController,
            decoration: InputDecoration(
              hintText: 'أدخل رقم المعاملة / المرجع',
              prefixIcon: Icon(Icons.receipt_long),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 16),
          Text('إرفاق صورة الإشعار (مطلوب)', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (pickedFile != null) {
                setState(() {
                  _receiptFile = File(pickedFile.path);
                  _receiptFileName = pickedFile.name;
                });
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _receiptFileName != null ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _receiptFileName != null ? Icons.check_circle : Icons.upload_file,
                    color: _receiptFileName != null ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _receiptFileName ?? 'اضغط هنا لرفع صورة إشعار التحويل',
                      style: TextStyle(
                        color: _receiptFileName != null ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: _receiptFileName != null ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isUploadingReceipt ? null : () async {
              final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
              if (amount <= 0 || _transactionIdController.text.trim().isEmpty || _receiptFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('الرجاء إدخال المبلغ ورقم المعاملة وإرفاق صورة الإشعار أولاً ⚠️'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _isUploadingReceipt = true;
              });

              final messenger = ScaffoldMessenger.of(context);

              try {
                final String? downloadUrl = await StorageService().uploadImage(
                  _receiptFile!,
                  'receipts',
                );

                if (downloadUrl == null) {
                  throw Exception('فشل في رفع صورة إشعار التحويل');
                }

                await _firestoreService.submitDepositRequest(
                  userId: _userId,
                  amount: amount,
                  bankAccountName: _selectedPaymentMethod,
                  receiptImageUrl: downloadUrl,
                  transactionRef: _transactionIdController.text.trim(),
                );

                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('تم إرسال طلب شحن الرصيد للمراجعة بنجاح ✅', style: TextStyle(color: Colors.black)),
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                );
                setState(() {
                  _isAddingFunds = false;
                  _isUploadingReceipt = false;
                  _receiptFile = null;
                  _receiptFileName = null;
                  _transactionIdController.clear();
                  _amountController.clear();
                });
              } catch (e) {
                setState(() {
                  _isUploadingReceipt = false;
                });
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ أثناء إرسال الطلب: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isUploadingReceipt
                ? CircularProgressIndicator(color: Colors.black)
                : Text('تأكيد وإرسال الطلب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. Transactions List Component
  // =========================================================================
  Widget _buildTransactionsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getTransactionsStream(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final txs = snapshot.data ?? [];

        if (txs.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'لا توجد عمليات سابقة',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: txs.length,
          itemBuilder: (context, index) {
            final tx = txs[index];
            final amount = tx['amount']?.toString() ?? '0';
            final isDeposit = tx['type'] == 'deposit';
            final title = tx['bankAccountName'] ?? (isDeposit ? 'شحن رصيد' : 'سحب رصيد');
            final accountNumber = tx['accountNumber'] as String?;
            final holderName = tx['accountHolderName'] as String?;

            String dateStr = '';
            if (tx['createdAt'] != null) {
              final dt = tx['createdAt'].toDate();
              dateStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
            }

            String statusText = '';
            Color statusColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54);
            if (tx['status'] == 'pending') {
              statusText = isDeposit ? ' (قيد المراجعة)' : ' (قيد التحويل للمستفيد)';
              statusColor = Colors.orangeAccent;
            } else if (tx['status'] == 'approved') {
              statusText = isDeposit ? ' (تم الشحن بنجاح)' : ' (تم الإيداع في حسابك)';
              statusColor = Colors.green;
            } else if (tx['status'] == 'rejected') {
              statusText = isDeposit ? ' (مرفوض)' : ' (مرفوض ومسترد)';
              statusColor = Colors.red;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDeposit
                      ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                      : Colors.orangeAccent.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDeposit
                          ? AppTheme.primaryBlue.withValues(alpha: 0.15)
                          : Colors.orangeAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isDeposit ? AppTheme.primaryBlue : Colors.orangeAccent,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (statusText.isNotEmpty)
                              Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        if (accountNumber != null && accountNumber.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            'الحساب: $accountNumber ${holderName != null ? "($holderName)" : ""}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
                          ),
                        ],
                        SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${isDeposit ? '+' : '-'}$amount ج.س',
                    style: TextStyle(
                      color: isDeposit ? AppTheme.primaryBlue : Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
