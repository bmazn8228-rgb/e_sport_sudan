import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  bool _isAddingFunds = false;
  bool _isUploadingReceipt = false;
  String _selectedPaymentMethod = 'بنكك (Bankak - بنك الخرطوم)';
  final _transactionIdController = TextEditingController();
  final _amountController = TextEditingController();
  File? _receiptFile;
  String? _receiptFileName;

  final FirestoreService _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _transactionIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

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
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryRed.withValues(alpha: 0.1)],
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
                      final balance = snapshot.data ?? 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الرصيد المتاح', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            '${balance.toStringAsFixed(2)} ج.س',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
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
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
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
                      initialValue: _selectedPaymentMethod,
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
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'أدخل قيمة الرصيد (ج.س)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
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
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _receiptFileName != null ? AppTheme.primaryBlue : Colors.white24,
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _receiptFileName != null ? Icons.check_circle : Icons.upload_file,
                              color: _receiptFileName != null ? AppTheme.primaryBlue : Colors.white70,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _receiptFileName ?? 'اضغط هنا لرفع صورة إشعار التحويل',
                                style: TextStyle(
                                  color: _receiptFileName != null ? AppTheme.primaryBlue : Colors.white70,
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
                      onPressed: _isUploadingReceipt ? null : () async {
                        final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
                        if (amount <= 0 || _transactionIdController.text.trim().isEmpty || _receiptFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('الرجاء إدخال المبلغ ورقم المعاملة وإرفاق صورة الإشعار أولاً ⚠️'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        setState(() {
                          _isUploadingReceipt = true;
                        });

                        // Capture messenger before async gap
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          final String fileName = '${_userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          final ref = FirebaseStorage.instance.ref().child('receipts/$fileName');
                          await ref.putFile(_receiptFile!);
                          final String downloadUrl = await ref.getDownloadURL();

                          await _firestoreService.submitDepositRequest(
                            userId: _userId,
                            amount: amount,
                            bankAccountName: _selectedPaymentMethod,
                            receiptImageUrl: downloadUrl,
                            transactionRef: _transactionIdController.text.trim(),
                          );
                          
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
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
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isUploadingReceipt
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('تأكيد وإرسال الطلب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            
            const Text('سجل العمليات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Transactions List
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getTransactionsStream(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }
                
                final txs = snapshot.data ?? [];
                
                if (txs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'لا توجد عمليات سابقة',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    final amount = tx['amount']?.toString() ?? '0';
                    final isPositive = tx['type'] == 'deposit';
                    final title = tx['bankAccountName'] ?? 'عملية مالية';
                    
                    String dateStr = '';
                    if (tx['createdAt'] != null) {
                      final dt = tx['createdAt'].toDate();
                      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                    }
                    
                    String statusText = '';
                    Color statusColor = Colors.white54;
                    if (tx['status'] == 'pending') {
                      statusText = ' (قيد المراجعة)';
                      statusColor = Colors.orangeAccent;
                    } else if (tx['status'] == 'approved') {
                      statusText = ' (تم القبول)';
                      statusColor = AppTheme.primaryBlue;
                    } else if (tx['status'] == 'rejected') {
                      statusText = ' (مرفوض)';
                      statusColor = Colors.red;
                    }

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
                              color: isPositive ? AppTheme.primaryBlue.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isPositive ? Icons.arrow_downward : Icons.arrow_upward, color: isPositive ? AppTheme.primaryBlue : Colors.red, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                    if (statusText.isNotEmpty)
                                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(
                            '${isPositive ? '+' : '-'}$amount',
                            style: TextStyle(
                              color: isPositive ? AppTheme.primaryBlue : Colors.red,
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
            ),
          ],
        ),
      ),
    );
  }
}
