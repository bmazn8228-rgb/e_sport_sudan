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
        SnackBar(content: Text('الرجاء إدخال جميع البيانات ⚠️'), backgroundColor: Colors.red),
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
          SnackBar(content: Text('تمت إضافة الحساب بنجاح ✅'), backgroundColor: AppTheme.primaryBlue),
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
        title: Text('إدارة الحسابات البنكية', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حساباتك المسجلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getBankAccountsStream(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                final accounts = snapshot.data ?? [];

                if (accounts.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'لا توجد حسابات بنكية مضافة بعد',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.account_balance, color: AppTheme.primaryBlue, size: 24),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account['bankName'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  account['accountName'] ?? '',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                                ),
                                Text(
                                  account['accountNumber'] ?? '',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12, letterSpacing: 1.2),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  title: Text('حذف الحساب'),
                                  content: Text('هل أنت متأكد من حذف هذا الحساب؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text('حذف', style: TextStyle(color: Colors.red)),
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
            SizedBox(height: 24),
            if (!_isAdding)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isAdding = true;
                  });
                },
                icon: Icon(Icons.add, color: Colors.black),
                label: Text('إضافة حساب جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            if (_isAdding) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('إضافة حساب بنكي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 20),
                          onPressed: () {
                            setState(() {
                              _isAdding = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBank,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'اسم البنك / المحفظة',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      items: _bankOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBank = val);
                      },
                    ),
                    if (_selectedBank == 'أخرى') ...[
                      SizedBox(height: 16),
                      TextField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم البنك',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    TextField(
                      controller: _accountNameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم رباعي (كما في البنك)',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'رقم الحساب / رقم الهاتف',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text('حفظ الحساب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
