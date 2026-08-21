import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SafeDioLogger extends Interceptor {
  const SafeDioLogger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> ${options.method} ${_location(options)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint(
        '<-- ${response.statusCode ?? '-'} ${response.requestOptions.method} '
        '${_location(response.requestOptions)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '<-- ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${_location(err.requestOptions)}',
      );
    }
    handler.next(err);
  }

  String _location(RequestOptions options) =>
      '${options.baseUrl}${options.path}';
}
