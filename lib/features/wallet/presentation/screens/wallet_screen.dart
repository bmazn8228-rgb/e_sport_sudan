import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isAddingFunds = false;
  String _selectedPaymentMethod = 'بنكك (Bankak - بنك الخرطوم)';
  final _transactionIdController = TextEditingController();
  String? _receiptFileName;


  final List<Map<String, dynamic>> _transactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('المحفظة الإلكترونية', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, Color(0xFF0A1B10)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الرصيد المتاح', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text(
                    '0 ج.س',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  if (!_isAddingFunds)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAddingFunds = true;
                        });
                      },
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text('إضافة رصيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                ],
              ),
            ),
            
            // Add Funds Form
            if (_isAddingFunds) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('طلب إضافة رصيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                          onPressed: () {
                            setState(() {
                              _isAddingFunds = false;
                              _receiptFileName = null;
                              _transactionIdController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('اختر طريقة التحويل', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      dropdownColor: AppTheme.cardDark,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      items: ['بنكك (Bankak - بنك الخرطوم)', 'فوري (Fawry - بنك فيصل)', 'موبايل كاش', 'أخرى']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPaymentMethod = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _transactionIdController,
                      decoration: const InputDecoration(
                        hintText: 'أدخل رقم المعاملة',
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('إرفاق صورة الإشعار (مطلوب)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _receiptFileName = 'receipt_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.jpg';
                        });
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_transactionIdController.text.trim().isEmpty || _receiptFileName == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء إدخال رقم المعاملة وإرفاق صورة الإشعار أولاً ⚠️'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        // Submit logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إرسال طلب شحن الرصيد للمراجعة بنجاح ✅', style: TextStyle(color: Colors.black)),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                        setState(() {
                          _isAddingFunds = false;
                          _receiptFileName = null;
                          _transactionIdController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('تأكيد وإرسال الطلب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            
            const Text('سجل العمليات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Transactions List
            const Center(
              child: Text(
                'يتوفر قريباً',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tx['isPositive'] ? AppTheme.primaryGreen.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(tx['icon'], color: tx['isPositive'] ? AppTheme.primaryGreen : Colors.red, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(tx['date'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Text(
            tx['amount'],
            style: TextStyle(
              color: tx['isPositive'] ? AppTheme.primaryGreen : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
