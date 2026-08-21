import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'failure.dart';

String failureMessage(Object? error, {required String fallback}) =>
    error is Failure ? error.message : fallback;

Failure mapExceptionToFailure(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NoInternetFailure();
    }

    final status = error.response?.statusCode;
    final message = _responseMessage(error.response?.data);
    if (status == 400) {
      return BadRequestFailure(message ?? 'Permintaan tidak valid.');
    }
    if (status == 401) {
      return UnauthorizedFailure(
        message ?? 'Sesi tidak valid. Silakan masuk kembali.',
      );
    }
    if (status == 403) {
      return ForbiddenFailure(message ?? 'Anda tidak memiliki akses.');
    }
    if (status == 404) {
      return NotFoundFailure(message ?? 'Data tidak ditemukan.');
    }
    if (status != null && status >= 500) {
      return ServerFailure(message ?? 'Server sedang bermasalah. Coba lagi.');
    }
    return UnexpectedFailure(message ?? 'Permintaan tidak dapat diproses.');
  }
  if (error is PlatformException) return const StorageFailure();
  return const UnexpectedFailure();
}

String? _responseMessage(Object? data) {
  if (data is Map<String, dynamic>) return data['message'] as String?;
  if (data is Map) return data['message']?.toString();
  return null;
}
