import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';

class DepositRequestsScreen extends StatefulWidget {
  const DepositRequestsScreen({super.key});

  @override
  State<DepositRequestsScreen> createState() => _DepositRequestsScreenState();
}

class _DepositRequestsScreenState extends State<DepositRequestsScreen> {
  String _selectedStatus = 'pending';

  void _updateRequestStatus(BuildContext context, String docId, String status, double amount, String userId) async {
    try {
      await FirestoreService().updateDepositRequestStatus(docId, status, amount, userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? 'تم اعتماد الطلب وإيداع الرصيد بنجاح ✅' : 'تم رفض الطلب ❌'),
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
                  child: Text('خطأ في تحميل صورة الإشعار', style: TextStyle(color: Colors.white)),
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
        title: const Text('مراجعة طلبات شحن الرصيد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildStatusChip('pending', 'قيد المراجعة ⏳'),
                const SizedBox(width: 8),
                _buildStatusChip('approved', 'المعتمدة ✅'),
                const SizedBox(width: 8),
                _buildStatusChip('rejected', 'المرفوضة ❌'),
                const SizedBox(width: 8),
                _buildStatusChip('all', 'كافة المعاملات'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().getTransactionsByStatusStream(_selectedStatus == 'all' ? null : _selectedStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedStatus == 'pending' ? Icons.done_all : Icons.receipt_long,
                          size: 48,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedStatus == 'pending'
                              ? 'رائع! لا توجد طلبات إيداع معلقة حالياً'
                              : 'لا توجد طلبات مطابقة لهذا الفلتر',
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

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
                    final status = data['status'] ?? 'pending';

                    Color statusColor = Colors.orange;
                    String statusText = 'قيد المراجعة';
                    if (status == 'approved') {
                      statusColor = Colors.green;
                      statusText = 'معتمد وتم الإيداع ✅';
                    } else if (status == 'rejected') {
                      statusColor = Colors.red;
                      statusText = 'مرفوض ❌';
                    }

                    return Card(
                      color: AppTheme.cardDark,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$amount ج.س', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryBlue)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('طريقة الدفع: $bankName', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('رقم العملية / المرجع: $transactionRef', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('معرف اللاعب: $userId', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            const SizedBox(height: 14),
                            if (receiptUrl.isNotEmpty && receiptUrl != 'dummy_url')
                              GestureDetector(
                                onTap: () => _showImageDialog(context, receiptUrl),
                                child: Container(
                                  height: 140,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white24),
                                    image: DecorationImage(
                                      image: NetworkImage(receiptUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.zoom_in, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ),
                              ),
                            if (receiptUrl == 'dummy_url')
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Text('صورة إشعار تجريبية', style: TextStyle(color: Colors.orange, fontSize: 12)),
                              ),
                            if (status == 'pending') ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _updateRequestStatus(context, docId, 'approved', amount, userId),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, padding: const EdgeInsets.symmetric(vertical: 12)),
                                      icon: const Icon(Icons.check, color: Colors.black, size: 18),
                                      label: const Text('اعتماد وإيداع', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _updateRequestStatus(context, docId, 'rejected', amount, userId),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                      label: const Text('رفض الطلب', style: TextStyle(color: Colors.red)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String label) {
    final isSelected = _selectedStatus == statusKey;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.cardDark,
      onSelected: (_) => setState(() => _selectedStatus = statusKey),
    );
  }
}
