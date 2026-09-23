import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isChangingPassword = false;
  bool _isResetting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمات المرور الجديدة غير متطابقة.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (currentPass.trim() == newPass.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور الجديدة يجب أن تكون مختلفة عن كلمة المرور الحالية.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      await AuthService().changePassword(currentPass, newPass);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.black),
                SizedBox(width: 8),
                Text('تم تغيير كلمة المرور بنجاح 🎉', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: Duration(seconds: 4),
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'فشل تغيير كلمة المرور.';

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'كلمة المرور الحالية غير صحيحة. يرجى التأكد من كتابتها، أو استخدام زر استعادة كلمة المرور بالأسفل.';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور الجديدة ضعيفة جداً. يجب أن تتكون من 6 خانات أو أكثر.';
          break;
        case 'requires-recent-login':
          errorMessage = 'لأسباب أمنية، يرجى تسجيل الخروج ثم الدخول مجدداً لتغيير كلمة المرور.';
          break;
        case 'too-many-requests':
          errorMessage = 'تم حظر المحاولات مؤقتاً بسبب تكرار كلمة المرور الخاطئة. يرجى المحاولة بعد قليل.';
          break;
        case 'network-request-failed':
          errorMessage = 'تعذر الاتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مجدداً.';
          break;
        default:
          if (e.message != null && e.message!.isNotEmpty) {
            errorMessage = e.message!;
          }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = AuthService().currentUser?.email?.trim();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن العثور على بريد إلكتروني مرتبط بالحساب.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isResetting = true);

    try {
      await AuthService().sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mark_email_read, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم إرسال رابط إعادة تعيين كلمة المرور إلى $email. تفقد بريدك الوارد.',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'حدث خطأ أثناء إرسال الرابط.';
      if (e.code == 'too-many-requests') {
        msg = 'تم إرسال عدة طلبات مؤخراً. يرجى الانتظار قليلاً قبل المحاولة مجدداً.';
      } else if (e.code == 'network-request-failed') {
        msg = 'تعذر الاتصال بالشبكة. يرجى التحقق من الإنترنت.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = AuthService().currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('الأمان وكلمة المرور', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أمان الحساب الإلكتروني',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail.isNotEmpty ? userEmail : 'الحساب الحالي',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تغيير كلمة المرور',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'أدخل كلمة المرور الحالية لتأكيد هويتك، ثم اختر كلمة مرور جديدة وقوية.',
                      style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Current Password
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الحالية',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryBlue, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال كلمة المرور الحالية' : null,
                    ),
                    const SizedBox(height: 14),

                    // New Password
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور الجديدة (6 أحرف أو أرقام على الأقل)',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.primaryBlue, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور الجديدة';
                        if (v.trim().length < 6) return 'يجب أن تتكون من 6 خانات على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'تأكيد كلمة المرور الجديدة',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        prefixIcon: const Icon(Icons.check_circle_outline, color: AppTheme.primaryBlue, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                        if (v != _newPasswordController.text) return 'كلمات المرور غير متطابقة';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isChangingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isChangingPassword
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : const Text(
                                'حفظ كلمة المرور الجديدة',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),

                    // Forgot Password option
                    const Text(
                      'نسيت كلمة المرور الحالية؟',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يمكنك إرسال رابط لإعادة تعيين كلمة المرور مباشرة إلى بريدك الإلكتروني المسجل دون الحاجة لكلمة المرور الحالية.',
                      style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _isResetting ? null : _resetPassword,
                        icon: _isResetting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: AppTheme.primaryBlue, strokeWidth: 2),
                              )
                            : const Icon(Icons.email_outlined, color: AppTheme.primaryBlue, size: 18),
                        label: const Text(
                          'إرسال رابط استعادة كلمة المرور للبريد',
                          style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
