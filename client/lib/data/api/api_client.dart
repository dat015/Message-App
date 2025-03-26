import 'package:dio/dio.dart';
import '../../PlatformClient/config.dart';

class ApiClient {
  late Dio _dio;
  
  ApiClient({
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Map<String, String>? headers,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Config.baseUrl,  // Sử dụng Config.baseUrl
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: headers ?? {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('Request: ${options.method} ${options.uri}');
          print('Request data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response: ${response.statusCode} - ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('Error type: ${e.type}');
          print('Error message: ${e.message}');
          print('Error response: ${e.response?.data}');
          print('Error status code: ${e.response?.statusCode}');
          return handler.next(e);
        },
      ),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleResponse(Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return response.data;
      case 400:
        throw Exception('Bad Request: ${response.data}');
      case 401:
        throw Exception('Unauthorized: ${response.data}');
      case 403:
        throw Exception('Forbidden: ${response.data}');
      case 404:
        throw Exception('Not Found: ${response.data}');
      case 500:
        throw Exception('Server Error: ${response.data}');
      default:
        throw Exception('Unexpected status code: ${response.statusCode}');
    }
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout. Please check your network.');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return Exception('Receive timeout. Server took too long to respond.');
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data['message'] ?? e.message;
      return Exception('Error $statusCode: $message');
    } else if (e.type == DioExceptionType.cancel) {
      return Exception('Request was cancelled.');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}
