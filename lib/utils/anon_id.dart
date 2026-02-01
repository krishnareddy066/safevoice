import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

String generateAnonId() {
  final random = Random.secure();
  final randomBytes = List<int>.generate(16, (_) => random.nextInt(256));
  final bytes =
      utf8.encode(DateTime.now().toIso8601String()) + randomBytes;
  return sha256.convert(bytes).toString();
}

Future<String> getOrCreateAnonId() async {
  final prefs = await SharedPreferences.getInstance();
  String? anonId = prefs.getString('anon_id');

  if (anonId == null) {
    anonId = generateAnonId();
    await prefs.setString('anon_id', anonId);
  }

  return anonId;
}
