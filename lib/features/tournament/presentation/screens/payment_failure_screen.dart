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
        title: const Text('فشل عملية الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, size: 100, color: Colors.red),
              ),
              const SizedBox(height: 32),
              const Text(
                'عذراً، الرصيد غير كافٍ!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'لا تملك رصيداً كافياً في محفظتك الإلكترونية لإتمام التسجيل في هذه البطولة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildAmountRow('رسوم البطولة:', requiredAmount),
                    const Divider(color: Colors.white12, height: 24),
                    _buildAmountRow('الرصيد المتاح:', availableBalance, isError: true),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to wallet to recharge
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const WalletScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('شحن المحفظة الآن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to step 4
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('العودة لتغيير طريقة الدفع', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          '${amount.toInt()} ج.س',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isError ? Colors.red : Colors.white,
          ),
        ),
      ],
    );
  }
}
