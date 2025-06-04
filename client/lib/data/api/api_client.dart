import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:first_app/data/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../PlatformClient/config.dart';

class ApiClient {
  late Dio _dio;

  ApiClient({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Config.baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );

    // Thêm interceptor để thêm token và xử lý logs
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Thêm headers CORS
          options.headers['Access-Control-Allow-Origin'] = '*';
          options.headers['Access-Control-Allow-Methods'] =
              'GET, POST, PUT, DELETE, OPTIONS';
          options.headers['Access-Control-Allow-Headers'] =
              'Origin, Content-Type, Accept, Authorization';
          options.headers['Access-Control-Allow-Credentials'] = 'true';

          // 👉 Thêm Authorization nếu có token
          final token = await _getToken();
          print("token: $token");
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('Request: ${options.method} ${options.uri}');
          print('Request headers: ${options.headers}');
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

  // 🚀 Hàm lấy token từ SharedPreferences
   Future<String?> _getToken() async {
    return await StorageService.getToken();  // Sử dụng StorageService
  }

  // Request methods
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
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
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
