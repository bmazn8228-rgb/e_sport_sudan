import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;
  StorageService._internal();

  /// Uploads an image file to Firebase Storage and returns the download URL.
  Future<String?> uploadImage(File file, String folder) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final Reference ref = _storage.ref().child('$folder/$fileName');
      
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image to Storage: $e');
      return null;
    }
  }
}
