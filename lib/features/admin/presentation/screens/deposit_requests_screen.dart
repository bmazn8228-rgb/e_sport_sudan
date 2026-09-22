import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class DepositRequestsScreen extends StatelessWidget {
  const DepositRequestsScreen({super.key});

  void _updateRequestStatus(BuildContext context, String docId, String status, double amount, String userId) async {
    try {
      await FirestoreService().updateDepositRequestStatus(docId, status, amount, userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? 'تم اعتماد الطلب وإضافة الرصيد' : 'تم رفض الطلب'),
            backgroundColor: status == 'approved' ? AppTheme.primaryBlue : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('خطأ في تحميل الصورة', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('طلبات إيداع الرصيد'),
        backgroundColor: AppTheme.cardDark,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getPendingDepositRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('لا توجد طلبات معلقة حالياً', style: TextStyle(color: Colors.white70, fontSize: 16)),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index];
              final docId = data['id'] ?? '';
              
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final bankName = data['bankAccountName'] ?? 'غير معروف';
              final transactionRef = data['transactionRef'] ?? 'غير متوفر';
              final receiptUrl = data['receiptImageUrl'] ?? '';
              final userId = data['userId'] ?? '';

              return Card(
                color: AppTheme.cardDark,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المبلغ: $amount ج.س', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                          const Chip(
                            label: Text('قيد المراجعة', style: TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('طريقة الدفع: $bankName', style: const TextStyle(color: Colors.white70)),
                      Text('رقم المعاملة: $transactionRef', style: const TextStyle(color: Colors.white70)),
                      Text('رقم المستخدم: $userId', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 16),
                      if (receiptUrl.isNotEmpty && receiptUrl != 'dummy_url')
                        GestureDetector(
                          onTap: () => _showImageDialog(context, receiptUrl),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                              image: DecorationImage(
                                image: NetworkImage(receiptUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.zoom_in, color: Colors.white70, size: 40),
                            ),
                          ),
                        ),
                      if (receiptUrl == 'dummy_url')
                        const Text('صورة إشعار وهمية (تطوير)', style: TextStyle(color: Colors.orange)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateRequestStatus(context, docId, 'approved', amount, userId),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                              child: const Text('اعتماد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateRequestStatus(context, docId, 'rejected', amount, userId),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('رفض', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
