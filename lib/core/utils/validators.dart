class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب إدخال البريد الإلكتروني';
    }
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'مطلوب إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateSudanPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب إدخال رقم الهاتف';
    }
    // Matches +249 or 00249 followed by 9 or 1, then exactly 8 digits
    final phoneRegex = RegExp(r"^(?:\+249|00249)(?:9|1)\d{8}$");
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'يجب أن يبدأ بـ +249 أو 00249 متبوعاً بـ 9 أرقام (مثال: +249912345678)';
    }
    return null;
  }

  static String? validateName(String? value, {String fieldName = 'الاسم'}) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب إدخال $fieldName';
    }
    if (value.trim().length < 3) {
      return 'يجب أن يتكون $fieldName من 3 أحرف على الأقل';
    }
    return null;
  }

  static String? validateRequired(String? value, {String fieldName = 'هذا الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value, {String fieldName = 'القيمة'}) {
    if (value == null || value.trim().isEmpty) {
      return 'مطلوب إدخال $fieldName';
    }
    final number = double.tryParse(value.trim());
    if (number == null) {
      return 'يجب إدخال أرقام صحيحة فقط';
    }
    if (number < 0) {
      return '$fieldName لا يمكن أن تكون سالبة';
    }
    return null;
  }
}
