class NetworkException implements Exception {
  final int code;
  final String message;

  NetworkException({required this.code, required this.message});
}
