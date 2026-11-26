import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../zone/domain/zone.dart';
import '../domain/auth_models.dart';
import 'api_exception.dart';

class AuthRepository {
  const AuthRepository({http.Client? client, String? baseUrl})
    : _client = client,
      _baseUrl = baseUrl;

  final http.Client? _client;
  final String? _baseUrl;

  String get _root => (_baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/$'), '');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final client = _client ?? http.Client();
    final uri = Uri.parse('$_root$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await client
          .send(
            http.Request(method, uri)
              ..headers.addAll(headers)
              ..body = body == null ? '' : jsonEncode(body),
          )
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 10));
      return _decode(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Unable to connect to the server.',
      );
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> decoded;

    try {
      final value = jsonDecode(response.body);
      decoded = value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      decoded = <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        code: decoded['error'] as String? ?? 'REQUEST_FAILED',
        message: decoded['message'] as String? ??
            'Request failed (${response.statusCode}).',
      );
    }

    return decoded;
  }

  Future<AuthUser> registerPassenger(Map<String, dynamic> body) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/passenger/register',
      body: body,
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> registerDriver(Map<String, dynamic> body) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/driver/register',
      body: body,
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthSession> login({
    required String identifier,
    required String password,
    bool admin = false,
  }) async {
    final data = await _request(
      'POST',
      admin ? '/api/v1/auth/admin/login' : '/api/v1/auth/login',
      body: {'identifier': identifier, 'password': password},
    );
    return AuthSession.fromJson(data);
  }

  Future<AuthUser> fetchCurrentUser(String token) async {
    final data = await _request('GET', '/api/v1/auth/me', token: token);
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<TodaOption>> fetchTodas() async {
    final data = await _request('GET', '/api/v1/todas');
    final items = data['todas'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(TodaOption.fromJson)
        .toList();
  }

  Future<List<ZoneSummary>> fetchZones({required String token, bool admin = false}) async {
    final data = await _request(
      'GET',
      admin ? '/api/v1/admin/zones' : '/api/v1/zones',
      token: token,
    );
    final items = data['zones'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ZoneSummary.fromJson)
        .toList();
  }
}
