import 'package:flutter/material.dart';
import 'package:e_sport_sudan/core/theme/app_theme.dart';
import 'package:e_sport_sudan/core/services/auth_service.dart';
import 'package:e_sport_sudan/core/services/firestore_service.dart';
import 'package:e_sport_sudan/core/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ignController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final userModel = await FirestoreService().getUser(user.uid);
      if (userModel != null && mounted) {
        setState(() {
          _userModel = userModel;
          _nameController.text = userModel.displayName;
          _ignController.text = userModel.ign ?? '';
          _phoneController.text = userModel.phone;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userModel == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedModel = UserModel(
        uid: _userModel!.uid,
        email: _userModel!.email,
        displayName: _nameController.text.trim(),
        ign: _ignController.text.trim().isNotEmpty ? _ignController.text.trim() : null,
        phone: _phoneController.text.trim(),
        photoUrl: _userModel!.photoUrl,
        gameId: _userModel!.gameId,
        role: _userModel!.role,
        teamId: _userModel!.teamId,
        settings: _userModel!.settings,
      );

      await FirestoreService().saveUser(updatedModel);
      
      // Update Firebase Auth display name if needed
      await AuthService().currentUser?.updateDisplayName(updatedModel.displayName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح'), backgroundColor: AppTheme.primaryBlue),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء التحديث'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ignController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _ignController,
                      label: 'اسم الشهرة داخل اللعبة (IGN)',
                      icon: Icons.sports_esports,
                      validator: (v) => null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text('حفظ التغييرات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: AppTheme.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}
