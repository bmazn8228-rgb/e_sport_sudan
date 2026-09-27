import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class FinancialTransactionsScreen extends StatelessWidget {
  const FinancialTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('سجل المعاملات المالي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestoreService.getTransactionsStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
            }
            
            final txs = snapshot.data ?? [];
            
            if (txs.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد عمليات سابقة',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
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
                          color: isPositive ? AppTheme.primaryBlue.withOpacity(0.2) : Colors.red.withOpacity(0.2),
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
      ),
    );
  }
}
