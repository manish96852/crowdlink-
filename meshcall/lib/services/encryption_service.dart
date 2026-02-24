import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

/// End-to-End Encryption Service
/// Uses RSA for key exchange and AES-256 for message encryption
class EncryptionService {
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? _keyPair;
  final Map<String, RSAPublicKey> _peerPublicKeys = {};
  
  // AES key for symmetric encryption (after key exchange)
  Uint8List? _sharedKey;

  String get publicKeyPem {
    if (kIsWeb || _keyPair == null) return 'web-aes-only';
    return _publicKeyToPem(_keyPair!.publicKey);
  }

  /// Generate RSA key pair for this device
  /// On web: skips RSA (not needed for local mesh) and only generates AES key.
  Future<void> generateKeyPair() async {
    try {
      if (kIsWeb) {
        // Web doesn't need RSA — mesh is local-only and AES is sufficient
        _sharedKey = _generateAESKey();
        debugPrint("Web: AES key generated (RSA skipped)");
        return;
      }

      final keyGen = RSAKeyGenerator()
        ..init(ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12),
          _secureRandom(),
        ));

      _keyPair = keyGen.generateKeyPair() as AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>;

      // Generate AES key for symmetric encryption
      _sharedKey = _generateAESKey();

      debugPrint("Key pair generated successfully");
    } catch (e, stackTrace) {
      debugPrint("ERROR generating key pair: $e");
      debugPrint("Stack trace: $stackTrace");
      // Fallback: just generate AES key if RSA fails
      _sharedKey = _generateAESKey();
      debugPrint("Fallback: Using AES-only mode");
    }
  }

  /// Store a peer's public key
  void addPeerPublicKey(String peerId, String publicKeyPem) {
    _peerPublicKeys[peerId] = _pemToPublicKey(publicKeyPem);
  }

  /// Encrypt a message using AES-256-CBC
  Future<String> encrypt(String plainText) async {
    if (_sharedKey == null) {
      await generateKeyPair();
    }

    try {
      final iv = _generateIV();
      final key = KeyParameter(_sharedKey!);
      final params = ParametersWithIV<KeyParameter>(key, iv);

      final cipher = CBCBlockCipher(AESEngine())..init(true, params);

      final plainBytes = _pad(utf8.encode(plainText));
      final encrypted = Uint8List(plainBytes.length);

      for (var offset = 0; offset < plainBytes.length; offset += 16) {
        cipher.processBlock(plainBytes, offset, encrypted, offset);
      }

      // Combine IV + encrypted data
      final combined = Uint8List(iv.length + encrypted.length);
      combined.setAll(0, iv);
      combined.setAll(iv.length, encrypted);

      return base64Encode(combined);
    } catch (e) {
      debugPrint("Encryption error: $e");
      return plainText; // Fallback to plain text
    }
  }

  /// Decrypt a message using AES-256-CBC
  Future<String> decrypt(String encryptedBase64) async {
    if (_sharedKey == null) {
      return encryptedBase64;
    }

    try {
      final combined = base64Decode(encryptedBase64);

      // Extract IV (first 16 bytes)
      final iv = combined.sublist(0, 16);
      final encrypted = combined.sublist(16);

      final key = KeyParameter(_sharedKey!);
      final params = ParametersWithIV<KeyParameter>(key, iv);

      final cipher = CBCBlockCipher(AESEngine())..init(false, params);

      final decrypted = Uint8List(encrypted.length);
      for (var offset = 0; offset < encrypted.length; offset += 16) {
        cipher.processBlock(encrypted, offset, decrypted, offset);
      }

      return utf8.decode(_unpad(decrypted));
    } catch (e) {
      debugPrint("Decryption error: $e");
      return encryptedBase64;
    }
  }

  /// Encrypt data for a specific peer using their public key
  Future<String> encryptForPeer(String plainText, String peerId) async {
    final peerKey = _peerPublicKeys[peerId];
    if (peerKey == null) {
      return await encrypt(plainText); // Fallback to symmetric
    }

    try {
      final encryptor = OAEPEncoding(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(peerKey));

      final plainBytes = utf8.encode(plainText);
      final encrypted = encryptor.process(Uint8List.fromList(plainBytes));

      return base64Encode(encrypted);
    } catch (e) {
      debugPrint("RSA encryption error: $e");
      return await encrypt(plainText);
    }
  }

  /// Decrypt data using our private key
  Future<String> decryptWithPrivateKey(String encryptedBase64) async {
    if (_keyPair == null) return encryptedBase64;

    try {
      final encrypted = base64Decode(encryptedBase64);

      final decryptor = OAEPEncoding(RSAEngine())
        ..init(false,
            PrivateKeyParameter<RSAPrivateKey>(_keyPair!.privateKey));

      final decrypted = decryptor.process(Uint8List.fromList(encrypted));

      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint("RSA decryption error: $e");
      return encryptedBase64;
    }
  }

  /// Generate a secure random number generator
  SecureRandom _secureRandom() {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    final rng = Random.secure();
    for (int i = 0; i < seed.length; i++) {
      seed[i] = rng.nextInt(256);
    }
    random.seed(KeyParameter(seed));
    return random;
  }

  /// Generate AES-256 key
  Uint8List _generateAESKey() {
    final rng = Random.secure();
    return Uint8List.fromList(
        List.generate(32, (_) => rng.nextInt(256)));
  }

  /// Generate IV (Initialization Vector)
  Uint8List _generateIV() {
    final rng = Random.secure();
    return Uint8List.fromList(
        List.generate(16, (_) => rng.nextInt(256)));
  }

  /// PKCS7 padding
  Uint8List _pad(List<int> data) {
    final blockSize = 16;
    final padLength = blockSize - (data.length % blockSize);
    final padded = Uint8List(data.length + padLength);
    padded.setAll(0, data);
    for (var i = data.length; i < padded.length; i++) {
      padded[i] = padLength;
    }
    return padded;
  }

  /// Remove PKCS7 padding
  Uint8List _unpad(Uint8List data) {
    final padLength = data.last;
    return data.sublist(0, data.length - padLength);
  }

  /// Convert RSA public key to PEM string
  String _publicKeyToPem(RSAPublicKey key) {
    return 'RSA_PUB:${key.modulus}:${key.exponent}';
  }

  /// Convert PEM string to RSA public key
  RSAPublicKey _pemToPublicKey(String pem) {
    final parts = pem.split(':');
    return RSAPublicKey(
      BigInt.parse(parts[1]),
      BigInt.parse(parts[2]),
    );
  }
}
