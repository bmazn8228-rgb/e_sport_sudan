import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  final _firestoreService = FirestoreService();
  final _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isAdding = false;

  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  final List<String> _bankOptions = [
    'بنكك (بنك الخرطوم)',
    'فوري (بنك فيصل)',
    'موبايل كاش',
    'كاشي',
    'أخرى'
  ];
  String _selectedBank = 'بنكك (بنك الخرطوم)';

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _addAccount() async {
    final accountName = _accountNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    if (accountName.isEmpty || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال جميع البيانات ⚠️'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await _firestoreService.addBankAccount(_userId, {
        'bankName': _selectedBank == 'أخرى' ? _bankNameController.text.trim() : _selectedBank,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'createdAt': DateTime.now(),
      });
      setState(() {
        _isAdding = false;
        _accountNameController.clear();
        _accountNumberController.clear();
        _bankNameController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الحساب بنجاح ✅'), backgroundColor: AppTheme.primaryBlue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('إدارة الحسابات البنكية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حساباتك المسجلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getBankAccountsStream(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                final accounts = snapshot.data ?? [];

                if (accounts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'لا توجد حسابات بنكية مضافة بعد',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account['bankName'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  account['accountName'] ?? '',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  account['accountNumber'] ?? '',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.2),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppTheme.cardDark,
                                  title: const Text('حذف الحساب'),
                                  content: const Text('هل أنت متأكد من حذف هذا الحساب؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _firestoreService.deleteBankAccount(_userId, account['id']);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            if (!_isAdding)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAdding = true;
                  });
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('إضافة حساب جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            if (_isAdding) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('إضافة حساب بنكي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                          onPressed: () {
                            setState(() {
                              _isAdding = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      dropdownColor: AppTheme.cardDark,
                      decoration: const InputDecoration(
                        labelText: 'اسم البنك / المحفظة',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      items: _bankOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBank = val);
                      },
                    ),
                    if (_selectedBank == 'أخرى') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bankNameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم البنك',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _accountNameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم رباعي (كما في البنك)',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'رقم الحساب / رقم الهاتف',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('حفظ الحساب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
