import 'package:encrypt/encrypt.dart';

class InviteCodeEncryption {
  static final _key = Key.fromLength(32);
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key));

  static String encrypt(String plainText) =>
      _encrypter.encrypt(plainText, iv: _iv).base64;

  static String decrypt(String encrypted) =>
      _encrypter.decrypt64(encrypted, iv: _iv);
}
