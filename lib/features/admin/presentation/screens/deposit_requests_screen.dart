import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:e_sport_sudan/core/services/notification_service.dart';
import 'package:e_sport_sudan/core/widgets/esport_toast.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/features/auth/presentation/screens/login_screen.dart';

class DepositRequestsScreen extends StatefulWidget {
  const DepositRequestsScreen({super.key});

  @override
  State<DepositRequestsScreen> createState() => _DepositRequestsScreenState();
}

class _DepositRequestsScreenState extends State<DepositRequestsScreen> with SingleTickerProviderStateMixin {
  String _selectedStatus = 'pending';
  String _selectedTransactionType = 'deposit'; // 'deposit' or 'withdrawal'
  final FirestoreService _firestoreService = FirestoreService();

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: EdgeInsets.all(32),
                    color: Theme.of(context).colorScheme.surface,
                    child: Text('خطأ في تحميل صورة الإشعار', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black87,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Deposit Action Handlers
  // =========================================================================
  void _updateDepositStatus(BuildContext context, String docId, String status, double amount, String userId) async {
    try {
      await _firestoreService.updateDepositRequestStatus(docId, status, amount, userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? 'تم اعتماد الشحن وإيداع الرصيد للاعب بنجاح ✅' : 'تم رفض طلب الشحن ❌'),
          backgroundColor: status == 'approved' ? AppTheme.primaryBlue : Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      NotificationService.showCustomToast(context, title: 'إشعار النظام', message: 'خطأ: $e', type: ToastType.urgent);
    }
  }

  // =========================================================================
  // Withdrawal Action Handlers
  // =========================================================================
  void _confirmApproveWithdrawal(BuildContext context, Map<String, dynamic> data) {
    final docId = data['id'] ?? '';
    final userId = data['userId'] ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final bankName = data['bankAccountName'] ?? 'البنك';
    final accountNumber = data['accountNumber'] ?? 'غير متوفر';
    final holderName = data['accountHolderName'] ?? 'المستفيد';

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 26),
            SizedBox(width: 10),
            Text('تأكيد التحويل البنكي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل قمت بإيداع المبلغ في حساب اللاعب بنجاح؟', style: TextStyle(fontSize: 14)),
            SizedBox(height: 14),
            _buildDetailItem('المبلغ المحول:', '${amount.toStringAsFixed(2)} ج.س'),
            _buildDetailItem('البنك / المحفظة:', bankName),
            _buildDetailItem('اسم المستفيد:', holderName),
            _buildDetailItem('رقم الحساب:', accountNumber),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                '🔔 سيقوم النظام بإرسال إشعار فوري للاعب بتأكيد وصول الأموال إلى حسابه البنكي.',
                style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _firestoreService.approveWithdrawalRequest(
                  docId: docId,
                  userId: userId,
                  amount: amount,
                  bankName: bankName,
                  accountNumber: accountNumber,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تأكيد التحويل وإرسال الإشعار للاعب بنجاح! 💸✅', style: TextStyle(color: Colors.black)),
                    backgroundColor: Colors.greenAccent,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                NotificationService.showCustomToast(context, title: 'خطأ', message: '$e', type: ToastType.urgent);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('نعم، تم التحويل ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRejectWithdrawalDialog(BuildContext context, Map<String, dynamic> data) {
    final docId = data['id'] ?? '';
    final userId = data['userId'] ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final reasonController = TextEditingController(text: 'بيانات الحساب البنكي غير مطابقة أو خاطئة');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Text('رفض طلب السحب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سيتم إعادة مبلغ (${amount.toStringAsFixed(2)} ج.س) إلى محفظة اللاعب تلقائياً.', style: TextStyle(fontSize: 13)),
            SizedBox(height: 12),
            Text('سبب الرفض (سيظهر للاعب):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            SizedBox(height: 6),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الرفض...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('إلغاء', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.pop(dialogCtx);
              try {
                await _firestoreService.rejectWithdrawalRequest(
                  docId: docId,
                  userId: userId,
                  amount: amount,
                  reason: reason.isEmpty ? 'بيانات الحساب البنكي غير صحيحة' : reason,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم رفض الطلب واستعادة الرصيد إلى محفظة اللاعب ⚠️'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                NotificationService.showCustomToast(context, title: 'خطأ', message: '$e', type: ToastType.urgent);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('تأكيد الرفض واستعادة الرصيد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('إدارة العمليات المالية (إيداع وسحب)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Operation Type Switch (Deposit vs Withdrawal)
          Container(
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTransactionType = 'deposit'),
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTransactionType == 'deposit' ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: _selectedTransactionType == 'deposit' ? Colors.black : Theme.of(context).colorScheme.onSurface,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'طلبات الإيداع (شحن)',
                            style: TextStyle(
                              color: _selectedTransactionType == 'deposit' ? Colors.black : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTransactionType = 'withdrawal'),
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTransactionType == 'withdrawal' ? Colors.orangeAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: _selectedTransactionType == 'withdrawal' ? Colors.black : Theme.of(context).colorScheme.onSurface,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'طلبات السحب (تحويل)',
                            style: TextStyle(
                              color: _selectedTransactionType == 'withdrawal' ? Colors.black : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildStatusChip('pending', 'قيد الانتظار ⏳'),
                SizedBox(width: 8),
                _buildStatusChip('approved', 'المعتمدة ✅'),
                SizedBox(width: 8),
                _buildStatusChip('rejected', 'المرفوضة ❌'),
                SizedBox(width: 8),
                _buildStatusChip('all', 'كافة المعاملات'),
              ],
            ),
          ),
          SizedBox(height: 6),

          // Transaction Stream List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getTransactionsByStatusStream(
                _selectedStatus == 'all' ? null : _selectedStatus,
                type: _selectedTransactionType,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}', style: TextStyle(color: Colors.red)));
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
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30),
                        ),
                        SizedBox(height: 12),
                        Text(
                          _selectedStatus == 'pending'
                              ? (_selectedTransactionType == 'deposit'
                                  ? 'رائع! لا توجد طلبات إيداع معلقة حالياً'
                                  : 'رائع! لا توجد طلبات سحب معلقة حالياً')
                              : 'لا توجد طلبات مطابقة لهذا الفلتر',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final data = requests[index];
                    final isDeposit = (data['type'] ?? _selectedTransactionType) == 'deposit';
                    return isDeposit ? _buildDepositCard(context, data) : _buildWithdrawalCard(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Deposit Card Builder
  // =========================================================================
  Widget _buildDepositCard(BuildContext context, Map<String, dynamic> data) {
    final docId = data['id'] ?? '';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final bankName = data['bankAccountName'] ?? 'غير معروف';
    final transactionRef = data['transactionRef'] ?? 'غير متوفر';
    final receiptUrl = data['receiptImageUrl'] ?? '';
    final userId = data['userId'] ?? '';
    final status = data['status'] ?? 'pending';

    String dateStr = '';
    if (data['createdAt'] != null) {
      final dt = data['createdAt'].toDate();
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    }

    Color statusColor = Colors.orange;
    String statusText = 'قيد المراجعة ⏳';
    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'معتمد وتم الإيداع ✅';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'مرفوض ❌';
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_downward, color: AppTheme.primaryBlue, size: 20),
                    SizedBox(width: 6),
                    Text('+${amount.toStringAsFixed(2)} ج.س', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text('طريقة الدفع: $bankName', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 13)),
            SizedBox(height: 4),
            Text('رقم العملية / المرجع: $transactionRef', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 13)),
            SizedBox(height: 4),
            Text('معرف اللاعب: $userId', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
            if (dateStr.isNotEmpty) ...[
              SizedBox(height: 4),
              Text('التاريخ: $dateStr', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
            ],
            SizedBox(height: 14),
            if (receiptUrl.isNotEmpty && receiptUrl != 'dummy_url')
              GestureDetector(
                onTap: () => _showImageDialog(context, receiptUrl),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                    image: DecorationImage(
                      image: NetworkImage(receiptUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.zoom_in, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            if (status == 'pending') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateDepositStatus(context, docId, 'approved', amount, userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.check, color: Colors.black, size: 18),
                      label: Text('اعتماد وإيداع الرصيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateDepositStatus(context, docId, 'rejected', amount, userId),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.close, color: Colors.red, size: 18),
                      label: Text('رفض الطلب', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Withdrawal Card Builder (Admin Review)
  // =========================================================================
  Widget _buildWithdrawalCard(BuildContext context, Map<String, dynamic> data) {
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final bankName = data['bankAccountName'] ?? 'غير معروف';
    final accountNumber = data['accountNumber'] ?? 'غير متوفر';
    final holderName = data['accountHolderName'] ?? 'غير محدد';
    final userId = data['userId'] ?? '';
    final status = data['status'] ?? 'pending';
    final rejectReason = data['rejectReason'] as String?;

    String dateStr = '';
    if (data['createdAt'] != null) {
      final dt = data['createdAt'].toDate();
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    }

    Color statusColor = Colors.orangeAccent;
    String statusText = 'قيد انتظار التحويل ⏳';
    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'تم التحويل والإيداع للاعب ✅';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'مرفوض ومسترد ❌';
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 6),
                    Text(
                      '${amount.toStringAsFixed(2)} ج.س',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orangeAccent),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Bank details
            _buildDetailItem('البنك / المحفظة:', bankName),
            _buildDetailItem('اسم المستفيد:', holderName),

            // Account number with copy button
            Row(
              children: [
                Text('رقم الحساب / الهاتف:', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                SizedBox(width: 8),
                SelectableText(
                  accountNumber,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
                SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: accountNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ رقم الحساب بنجاح 📋: $accountNumber'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, size: 13, color: AppTheme.primaryBlue),
                        SizedBox(width: 4),
                        Text('نسخ', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 6),
            Text('معرف اللاعب: $userId', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
            if (dateStr.isNotEmpty) ...[
              SizedBox(height: 3),
              Text('وقت الطلب: $dateStr', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11)),
            ],

            if (rejectReason != null && rejectReason.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('سبب الرفض: $rejectReason', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
              ),
            ],

            // Action Buttons for Pending Withdrawal
            if (status == 'pending') ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmApproveWithdrawal(context, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: Text(
                        'تأكيد التحويل وإشعار اللاعب',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectWithdrawalDialog(context, data),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(Icons.close, color: Colors.red, size: 18),
                      label: Text('رفض الطلب', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusKey, String label) {
    final isSelected = _selectedStatus == statusKey;
    final activeColor = _selectedTransactionType == 'deposit' ? AppTheme.primaryBlue : Colors.orangeAccent;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface, fontSize: 12)),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: Theme.of(context).colorScheme.surface,
      onSelected: (_) => setState(() => _selectedStatus = statusKey),
    );
  }
}
