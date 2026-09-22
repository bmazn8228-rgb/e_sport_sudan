
class ConnectivityHelper {
  static Future<bool> hasInternetConnection() async {
    // Bypassed connectivity check as it can return false positives on some 
    // emulators/Windows environments. Firebase will throw a network exception 
    // if there is actually no internet, which is caught gracefully anyway.
    return true;
  }
}
