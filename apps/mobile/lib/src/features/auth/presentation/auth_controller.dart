import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/secure_token_store.dart';
import '../domain/auth_models.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository, SecureTokenStore? store})
    : _repository = repository ?? const AuthRepository(),
      _store = store ?? const SecureTokenStore();

  final AuthRepository _repository;
  final SecureTokenStore _store;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _token;
  String? _error;
  bool _isBusy = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _begin() {
    _isBusy = true;
    _error = null;
    notifyListeners();
  }

  void _end() {
    _isBusy = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setUnauthenticated(String? message) {
    _status = AuthStatus.unauthenticated;
    _user = null;
    _token = null;
    _error = message;
  }

  Future<void> restore() async {
    _begin();

    try {
      final token = await _store.readToken();

      if (token == null || token.isEmpty) {
        _setUnauthenticated(null);
        return;
      }

      try {
        final user = await _repository.fetchCurrentUser(token);
        _status = AuthStatus.authenticated;
        _user = user;
        _token = token;
        _error = null;
      } on ApiException catch (error) {
        if (error.isAuthFailure) {
          await _store.clear();
        }
        _setUnauthenticated(error.message);
      }
    } catch (_) {
      _setUnauthenticated('Unable to restore the saved session.');
    } finally {
      _end();
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) {
    return _authenticate(identifier: identifier, password: password);
  }

  Future<bool> adminLogin({
    required String identifier,
    required String password,
  }) {
    return _authenticate(
      identifier: identifier,
      password: password,
      admin: true,
    );
  }

  Future<bool> _authenticate({
    required String identifier,
    required String password,
    bool admin = false,
  }) async {
    _begin();

    try {
      final session = await _repository.login(
        identifier: identifier,
        password: password,
        admin: admin,
      );
      await _store.writeToken(session.token);
      _status = AuthStatus.authenticated;
      _user = session.user;
      _token = session.token;
      _error = null;
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Unable to connect to the server.';
      return false;
    } finally {
      _end();
    }
  }

  Future<bool> registerPassenger(Map<String, dynamic> body) async {
    _begin();

    try {
      await _repository.registerPassenger(body);
      _error = null;
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Unable to connect to the server.';
      return false;
    } finally {
      _end();
    }
  }

  Future<bool> registerDriver(Map<String, dynamic> body) async {
    _begin();

    try {
      await _repository.registerDriver(body);
      _error = null;
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Unable to connect to the server.';
      return false;
    } finally {
      _end();
    }
  }

  Future<void> logout() async {
    final token = _token;

    if (token != null && token.isNotEmpty) {
      try {
        await _repository.logout(token);
      } on ApiException catch (_) {
        _error = null;
      }
    }

    await _store.clear();
    _setUnauthenticated(null);
    notifyListeners();
  }

  Future<void> expireSession([
    String message = 'Your session has expired. Please sign in again.',
  ]) async {
    await _store.clear();
    _setUnauthenticated(message);
    notifyListeners();
  }
}
