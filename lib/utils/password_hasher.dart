import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 passwords stored as `salt:hash`.
class PasswordHasher {
  const PasswordHasher._();

  static final Random _random = Random.secure();

  static String hash(String password, {String? salt}) {
    final usedSalt = salt ?? _newSalt();
    final digest = sha256.convert(utf8.encode('$usedSalt$password'));
    return '$usedSalt:$digest';
  }

  static bool verify(String password, String stored) {
    final separator = stored.indexOf(':');
    if (separator <= 0 || separator >= stored.length - 1) return false;
    final salt = stored.substring(0, separator);
    return hash(password, salt: salt) == stored;
  }

  static String _newSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
