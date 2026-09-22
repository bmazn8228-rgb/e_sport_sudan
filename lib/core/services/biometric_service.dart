import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _emailKey = 'secure_login_email';
  static const String _passwordKey = 'secure_login_password';

  /// Check if the device has hardware support for biometrics and has biometrics enrolled.
  Future<bool> canAuthenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Attempts to authenticate the user with biometrics or device credentials.
  Future<bool> authenticate({String reason = 'يرجى تأكيد هويتك للمتابعة'}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allows fallback to PIN/pattern
        ),
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Saves the user credentials securely.
  Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  /// Retrieves the saved credentials. Returns a map with 'email' and 'password', or null if not found.
  Future<Map<String, String>?> getCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);

    if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  /// Checks if there are credentials saved.
  Future<bool> hasSavedCredentials() async {
    final creds = await getCredentials();
    return creds != null;
  }

  /// Clears the saved credentials.
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }
}

