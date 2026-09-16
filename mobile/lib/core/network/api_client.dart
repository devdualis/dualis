import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../security/secure_storage_service.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService _secureStorage;

  static Future<String?>? _refreshFuture;

  ApiClient({Dio? customDio, SecureStorageService? secureStorage})
      : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        _secureStorage = secureStorage ?? SecureStorageService() {
    dio.interceptors.add(
      InterceptorsWrapper(onError: _onError),
    );
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = error.requestOptions;
    final isUnauthorized = error.response?.statusCode == 401;
    final isExemptFromRefresh =
        requestOptions.extra['skipAuthRefresh'] == true;
    final alreadyRetried = requestOptions.extra['isAuthRetry'] == true;

    if (!isUnauthorized || isExemptFromRefresh || alreadyRetried) {
      return handler.next(error);
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      return handler.next(error);
    }

    try {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra['isAuthRetry'] = true;
      final response = await dio.fetch(requestOptions);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(error);
    }
  }

  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _performRefresh() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuthRefresh': true}),
      );

      final data = response.data;
      final newAccessToken = data?['accessToken'] as String?;
      final newRefreshToken = data?['refreshToken'] as String?;
      final userId = data?['user']?['id'] as String?;
      if (newAccessToken == null || newRefreshToken == null) return null;

      await _secureStorage.persistTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        userId: userId ?? await _secureStorage.getUserId() ?? '',
      );

      return newAccessToken;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAll();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
