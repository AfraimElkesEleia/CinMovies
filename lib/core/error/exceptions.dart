class ServerException implements Exception {
  const ServerException({required this.message});

  final String message;
}

class ValidationException implements Exception {
  const ValidationException({required this.message});

  final String message;
}

class AuthenticationRequiredException implements Exception {
  const AuthenticationRequiredException({
    this.message = 'Please sign in again to continue.',
  });

  final String message;
}
