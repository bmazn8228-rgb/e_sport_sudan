import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/features/wallet/presentation/screens/wallet_screen.dart';

class PaymentFailureScreen extends StatelessWidget {
  final double requiredAmount;
  final double availableBalance;

  const PaymentFailureScreen({
    super.key,
    required this.requiredAmount,
    required this.availableBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('فشل عملية الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cancel_outlined, size: 100, color: Colors.red),
              ),
              SizedBox(height: 32),
              Text(
                'عذراً، الرصيد غير كافٍ!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 16),
              Text(
                'لا تملك رصيداً كافياً في محفظتك الإلكترونية لإتمام التسجيل في هذه البطولة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10)),
                ),
                child: Column(
                  children: [
                    _buildAmountRow(context, 'رسوم البطولة:', requiredAmount),
                    Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12), height: 24),
                    _buildAmountRow(context, 'الرصيد المتاح:', availableBalance, isError: true),
                  ],
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to wallet to recharge
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => WalletScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('شحن المحفظة الآن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to step 4
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('العودة لتغيير طريقة الدفع', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(BuildContext context, String label, double amount, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        Text(
          '${amount.toInt()} ج.س',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isError ? Colors.red : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
