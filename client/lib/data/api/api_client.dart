import 'package:dio/dio.dart';

import '../../PlatformClient/config.dart';

class ApiClient {
  late Dio _dio;
  String baseUrl = Config.baseUrl;
  ApiClient({
    int connectTimeout = 5000,
    int receiveTimeout = 3000,
    Map<String, String>? headers,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: connectTimeout),
        receiveTimeout: Duration(milliseconds: receiveTimeout),
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

  // GET request
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

  // POST request
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

  // PUT request
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

  // DELETE request
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

  // Xử lý phản hồi
  dynamic _handleResponse(Response response) {
    switch (response.statusCode) {
      case 200: // OK
      case 201: // Created
        return response.data; // Trả về dữ liệu thô từ server
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

  // Xử lý lỗi từ DioException
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