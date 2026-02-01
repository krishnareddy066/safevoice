import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class AudioUploadService {
  static Future<String> uploadAudio({
    required File audioFile,
    required String reportId,
  }) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('report_audio')
          .child('$reportId.m4a');

      final metadata = SettableMetadata(
        contentType: 'audio/m4a',
      );

      final task = ref.putFile(audioFile, metadata);

      final snapshot = await task.timeout(
        const Duration(seconds: 30),
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception("Audio upload failed: $e");
    }
  }
}
