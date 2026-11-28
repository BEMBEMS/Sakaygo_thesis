class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  bool get isAuthFailure =>
      statusCode == 401 ||
      const <String>{
        'AUTH_TOKEN_REQUIRED',
        'AUTH_TOKEN_INVALID',
        'AUTH_USER_INVALID',
        'AUTH_REQUIRED',
      }.contains(code);

  @override
  String toString() => message;
}
