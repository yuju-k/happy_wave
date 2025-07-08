import 'package:bcrypt/bcrypt.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

final class SecurityUtil {
  static final String chatEncryptKey = "happywaveMessageEncryptKey123456";
  static final _key = encrypt.Key.fromUtf8(chatEncryptKey);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static String encryptPassword(String plainText) {
    return BCrypt.hashpw(plainText, BCrypt.gensalt());
  }

  static bool checkPW(String input, String password) {
    return BCrypt.checkpw(input, password);
  }

  static String encryptChat(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptChat(String encryptedChat) {
    final parts = encryptedChat.split(':');
    if (parts.length != 2) {
      return encryptedChat;
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    return _encrypter.decrypt(encrypted, iv: iv);
  }
}
