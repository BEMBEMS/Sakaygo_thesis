import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStore {
  const SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage;

  static const String _tokenKey = 'access_token';

  final FlutterSecureStorage? _storage;

  FlutterSecureStorage get _effectiveStorage =>
      _storage ?? const FlutterSecureStorage();

  Future<String?> readToken() => _effectiveStorage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _effectiveStorage.write(key: _tokenKey, value: token);

  Future<void> clear() => _effectiveStorage.delete(key: _tokenKey);
}
