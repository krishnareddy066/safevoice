import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  static Future<String> uploadReportImage({
    required File imageFile,
    required String reportId,
  }) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('report_images')
          .child('$reportId.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final task = ref.putFile(imageFile, metadata);

      final snapshot = await task.timeout(
        const Duration(seconds: 25),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Image upload failed: $e");
    }
  }
}
