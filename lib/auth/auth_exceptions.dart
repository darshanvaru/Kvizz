class AuthUnauthorizedException implements Exception {
  final String message;
  AuthUnauthorizedException([this.message = 'Unauthorized']);
}

class AuthNetworkException implements Exception {
  final String message;
  AuthNetworkException(this.message);
}
