import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateAnonId() {
  final random = Random.secure();
  final randomBytes = List<int>.generate(16, (_) => random.nextInt(256));
  final bytes = utf8.encode(DateTime.now().toIso8601String()) + randomBytes;
  return sha256.convert(bytes).toString();
}
