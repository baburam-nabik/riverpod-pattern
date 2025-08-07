import 'package:dio/dio.dart';

abstract class AppException implements Exception {
  final int? statusCode;
  final String message;
  const AppException(this.message, {this.statusCode});
  @override
  String toString() => '${runtimeType.toString()}($statusCode): $message';

  static AppException from(dynamic error) {
    if (error is AppException) return error;
    if (error is DioException) {
      return NetworkException(
        error.message ?? 'Network error',
        statusCode: error.response?.statusCode,
      );
    }
    if (error is FormatException) {
      return ParsingException(error.message);
    }
    return UnknownException(error.toString());
  }
}

class NetworkException extends AppException {
  const NetworkException(String message, {int? statusCode})
    : super(message, statusCode: statusCode);
}

class ParsingException extends AppException {
  const ParsingException(String message, {int? statusCode})
    : super(message, statusCode: statusCode);
}

class UnknownException extends AppException {
  const UnknownException(String message, {int? statusCode})
    : super(message, statusCode: statusCode);
}
