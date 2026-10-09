import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// المفتاح الافتراضي لـ ImgBB API
  static String defaultApiKey = 'ffd27eb128de61ce3663eaec681d29ea';

  /// مفتاح مخصص يمكن تمريره برمجياً أثناء التشغيل
  static String? customApiKey;

  /// ذاكرة تخزين مؤقتة للمفتاح المسترجع من Firestore
  static String? _cachedFirestoreKey;
  static DateTime? _lastKeyFetchTime;

  /// تعيين المفتاح يدوياً في أي وقت
  static void setApiKey(String key) {
    customApiKey = key.trim();
  }

  /// استرجاع مفتاح الـ API الفعال (الأولوية: المخصص -> Firestore -> الافتراضي)
  Future<String> getEffectiveApiKey() async {
    if (customApiKey != null && customApiKey!.trim().isNotEmpty) {
      return customApiKey!.trim();
    }

    // محاولة جلب المفتاح من Firestore مع كاش لمدة 10 دقائق
    final now = DateTime.now();
    if (_cachedFirestoreKey != null &&
        _lastKeyFetchTime != null &&
        now.difference(_lastKeyFetchTime!).inMinutes < 10) {
      return _cachedFirestoreKey!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_config')
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final firestoreKey = data['imgbbApiKey'] ?? data['imgbb_api_key'];
        if (firestoreKey is String && firestoreKey.trim().isNotEmpty) {
          _cachedFirestoreKey = firestoreKey.trim();
          _lastKeyFetchTime = now;
          return _cachedFirestoreKey!;
        }
      }
    } catch (e) {
      debugPrint('[StorageService] Could not fetch ImgBB API key from Firestore: $e');
    }

    return defaultApiKey.trim();
  }

  /// رفع ملف صورة إلى ImgBB واسترجاع الرابط المباشر
  /// [file]: ملف الصورة المحلي
  /// [folder]: وسيط اختياري لتسمية الملف وتنظيمه (متوافق مع الاستخدامات السابقة)
  Future<String?> uploadImage(File file, [String? folder]) async {
    try {
      if (!await file.exists()) {
        debugPrint('[StorageService] Error: File does not exist: ${file.path}');
        return null;
      }

      final String apiKey = await getEffectiveApiKey();
      if (apiKey.isEmpty || apiKey == 'YOUR_IMGBB_API_KEY_HERE') {
        debugPrint(
          '[StorageService] ⚠️ تنبيه: يرجى إدخال مفتاح ImgBB API في StorageService.defaultApiKey '
          'أو في Firestore داخل settings/app_config بالحقل imgbbApiKey',
        );
      }

      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['key'] = apiKey;

      final String rawName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String folderPrefix = (folder != null && folder.isNotEmpty)
          ? '${folder.replaceAll('/', '_')}_'
          : '';
      request.fields['name'] = '$folderPrefix${DateTime.now().millisecondsSinceEpoch}_$rawName';

      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      // مهلة 60 ثانية لتناسب سرعات الإنترنت في السودان
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final String? directUrl = responseData['data']['url'] as String?;
          final String? displayUrl = responseData['data']['display_url'] as String?;
          final String finalUrl = directUrl ?? displayUrl ?? '';
          if (finalUrl.isNotEmpty) {
            debugPrint('[StorageService] ImgBB upload succeeded: $finalUrl');
            return finalUrl;
          }
        }
      }

      debugPrint('[StorageService] ImgBB upload failed with status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[StorageService] Exception during ImgBB upload: $e');
      return null;
    }
  }

  /// رفع صورة عبر مصفوفة بايتات (Uint8List)
  Future<String?> uploadBytes(
    Uint8List bytes, {
    required String fileName,
    String? folder,
  }) async {
    try {
      final String apiKey = await getEffectiveApiKey();
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['key'] = apiKey;

      final String folderPrefix = (folder != null && folder.isNotEmpty)
          ? '${folder.replaceAll('/', '_')}_'
          : '';
      request.fields['name'] = '$folderPrefix${DateTime.now().millisecondsSinceEpoch}_$fileName';

      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: fileName),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data']['url'] ?? responseData['data']['display_url']) as String?;
        }
      }

      debugPrint('[StorageService] ImgBB uploadBytes failed: ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[StorageService] Exception during ImgBB uploadBytes: $e');
      return null;
    }
  }
}
