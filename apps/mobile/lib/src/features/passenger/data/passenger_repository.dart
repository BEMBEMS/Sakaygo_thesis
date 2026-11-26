import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../auth/data/api_exception.dart';
import '../domain/passenger_models.dart';

class PassengerRepository {
  const PassengerRepository({this.client, this.baseUrl});

  final http.Client? client;
  final String? baseUrl;

  String get _root =>
      (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/$'), '');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    required String token,
    Map<String, dynamic>? body,
  }) async {
    final activeClient = client ?? http.Client();
    final uri = Uri.parse('$_root$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await activeClient
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
      if (client == null) {
        activeClient.close();
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

  Future<PassengerProfile> fetchProfile(String token) async {
    final data = await _request(
      'GET',
      '/api/v1/users/passenger/me',
      token: token,
    );
    return PassengerProfile.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  Future<PassengerProfile> updateCurrentLocation({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    final data = await _request(
      'PATCH',
      '/api/v1/passenger/me/location',
      token: token,
      body: {'latitude': latitude, 'longitude': longitude},
    );
    return PassengerProfile.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  Future<PassengerRequest> createWaitingRequest({
    required String token,
    required double pickupLatitude,
    required double pickupLongitude,
    required String destinationName,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/passenger/requests/waiting-here',
      token: token,
      body: {
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'destinationName': destinationName,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
      },
    );
    return PassengerRequest.fromJson(
      data['request'] as Map<String, dynamic>,
    );
  }

  Future<PassengerRequest?> fetchActiveRequest(String token) async {
    final data = await _request(
      'GET',
      '/api/v1/passenger/requests/active',
      token: token,
    );
    final request = data['request'];
    if (request == null) {
      return null;
    }
    return PassengerRequest.fromJson(request as Map<String, dynamic>);
  }
}
