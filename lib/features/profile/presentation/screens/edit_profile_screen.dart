import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final _gameController = TextEditingController();
  String _userEmail = '';
  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _userModel;
  File? _imageFile;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        _userEmail = user.email ?? '';

        UserModel? userModel;
        try {
          userModel = await FirestoreService()
              .getUser(user.uid)
              .timeout(Duration(seconds: 4), onTimeout: () => null);
        } catch (e) {
          debugPrint('Error getting user from firestore: $e');
        }

        // Determine best fallback values
        final fallbackName = (userModel?.displayName.isNotEmpty == true)
            ? userModel!.displayName
            : (user.displayName != null && user.displayName!.trim().isNotEmpty)
                ? user.displayName!.trim()
                : (user.email != null && user.email!.isNotEmpty)
                    ? user.email!.split('@').first
                    : 'لاعب إلكتروني';

        _userModel = userModel ??
            UserModel(
              uid: user.uid,
              email: _userEmail,
              displayName: fallbackName,
              phone: '',
              role: UserRole.player,
            );

        if (mounted) {
          setState(() {
            _nameController.text = _userModel!.displayName;
            _ignController.text = _userModel!.ign ?? '';
            _phoneController.text = _userModel!.phone;
            _gameController.text = _userModel!.gameId ?? '';
            _currentPhotoUrl = _userModel!.photoUrl ?? user.photoURL;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _loadUser: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء اختيار الصورة'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? uploadedPhotoUrl = _currentPhotoUrl;

      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
            
        final uploadTask = await storageRef.putFile(_imageFile!);
        uploadedPhotoUrl = await uploadTask.ref.getDownloadURL();
      }

      final updatedModel = UserModel(
        uid: user.uid,
        email: _userModel?.email.isNotEmpty == true ? _userModel!.email : (user.email ?? ''),
        displayName: _nameController.text.trim(),
        ign: _ignController.text.trim().isNotEmpty ? _ignController.text.trim() : null,
        phone: _phoneController.text.trim(),
        photoUrl: uploadedPhotoUrl,
        gameId: _gameController.text.trim().isNotEmpty ? _gameController.text.trim() : null,
        role: _userModel?.role ?? UserRole.player,
        teamId: _userModel?.teamId,
        settings: _userModel?.settings ?? UserSettings(),
      );

      await FirestoreService().saveUser(updatedModel);

      // Update Firebase Auth display name as well
      try {
        await user.updateDisplayName(updatedModel.displayName);
      } catch (_) {}

      _userModel = updatedModel;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.black),
                SizedBox(width: 8),
                Text('تم حفظ التغييرات بنجاح', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التحديث: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
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
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryBlue),
                  SizedBox(height: 16),
                  Text('جاري تحميل البيانات...', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar Header
                    Center(
                      child: GestureDetector(
                        onTap: _isSaving ? null : _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                                    Color(0xFF00E5FF).withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.6), width: 2),
                                image: _imageFile != null
                                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                    : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(_currentPhotoUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: (_imageFile == null && (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty))
                                  ? Center(
                                      child: Icon(Icons.person_outline, size: 48, color: AppTheme.primaryBlue),
                                    )
                                  : null,
                            ),
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.edit, size: 14, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _userEmail.isNotEmpty ? _userEmail : 'لاعب الرياضات الإلكترونية',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
                    ),
                    SizedBox(height: 24),

                    // Full Name
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: Icons.person,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم الكامل' : null,
                    ),
                    SizedBox(height: 16),

                    // In-Game Name (IGN)
                    _buildTextField(
                      controller: _ignController,
                      label: 'اسم الشهرة داخل اللعبة (IGN)',
                      hint: 'مثال: @Shadow_Sniper',
                      icon: Icons.sports_esports,
                      validator: (v) => null,
                    ),
                    SizedBox(height: 16),

                    // Game / Platform
                    _buildTextField(
                      controller: _gameController,
                      label: 'اللعبة المفضلة / المنصة',
                      hint: 'مثال: PUBG Mobile / EA FC 25',
                      icon: Icons.gamepad,
                      validator: (v) => null,
                    ),
                    SizedBox(height: 16),

                    // Phone Number
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف (اختياري)',
                      hint: 'مثال: 0912345678',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => null,
                    ),
                    SizedBox(height: 16),

                    // Read-only email notice
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'البريد الإلكتروني المرتبط: $_userEmail',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : Text(
                                'حفظ التغييرات',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), fontSize: 13),
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

