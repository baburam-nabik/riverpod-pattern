import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'app_exception.dart';

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

enum HttpMethod { get, post, patch, delete }

abstract class IApiService {
  Future<Either<Exception, T>> request<T>(
    String path, {
    HttpMethod method,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    required JsonFactory<T> parser,
  });
}

class ApiService implements IApiService {
  final Dio _dio;
  ApiService([Dio? dio]) : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://dummyjson.com/'));

  @override
  Future<Either<Exception, T>> request<T>(
    String path, {
    HttpMethod method = HttpMethod.get,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    required JsonFactory<T> parser,
  }) async {
    try {
      late Response response;
      switch (method) {
        case HttpMethod.get:
          response = await _dio.get(path, queryParameters: queryParameters);
          break;
        case HttpMethod.post:
          response = await _dio.post(path, data: data);
          break;
        case HttpMethod.patch:
          response = await _dio.patch(path, data: data);
          break;
        case HttpMethod.delete:
          response = await _dio.delete(path, data: data);
          break;
      }
      return right(parser(response.data));
    } catch (e) {
      return left(AppException.from(e));
    }
  }
}