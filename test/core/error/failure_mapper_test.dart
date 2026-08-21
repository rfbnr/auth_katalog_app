import 'package:auth_katalog_app/core/error/failure.dart';
import 'package:auth_katalog_app/core/error/failure_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _request = RequestOptions(path: '/anything');

DioException _transport(DioExceptionType type) =>
    DioException(requestOptions: _request, type: type);

DioException _status(int code, {Object? body}) => DioException(
  requestOptions: _request,
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: _request,
    statusCode: code,
    data: body,
  ),
);

void main() {
  group('transport problems are offline, not server errors', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ]) {
      test('$type maps to NoInternetFailure', () {
        expect(
          mapExceptionToFailure(_transport(type)),
          isA<NoInternetFailure>(),
        );
      });
    }
  });

  group('server responses map to their own failure', () {
    test('400 is a bad request', () {
      expect(mapExceptionToFailure(_status(400)), isA<BadRequestFailure>());
    });

    test('401 is unauthorized', () {
      expect(mapExceptionToFailure(_status(401)), isA<UnauthorizedFailure>());
    });

    test('403 is forbidden', () {
      expect(mapExceptionToFailure(_status(403)), isA<ForbiddenFailure>());
    });

    test('404 is not found', () {
      expect(mapExceptionToFailure(_status(404)), isA<NotFoundFailure>());
    });

    test('500, 502 and 503 are all server failures', () {
      for (final code in [500, 502, 503]) {
        expect(
          mapExceptionToFailure(_status(code)),
          isA<ServerFailure>(),
          reason: '$code must not be reported to the user as an offline error',
        );
      }
    });

    test('an unmapped status falls back to unexpected', () {
      expect(mapExceptionToFailure(_status(418)), isA<UnexpectedFailure>());
    });
  });

  group('user-facing message', () {
    test('a server error reads differently from an offline error', () {
      final offline = mapExceptionToFailure(
        _transport(DioExceptionType.connectionError),
      );
      final server = mapExceptionToFailure(_status(500));

      expect(offline.message, isNot(server.message));
      expect(offline.message, contains('koneksi'));
      expect(server.message, contains('Server'));
    });

    test('the API message wins over the default when present', () {
      final failure = mapExceptionToFailure(
        _status(400, body: {'message': 'Username salah'}),
      );

      expect(failure.message, 'Username salah');
    });

    test('a non-string message is coerced rather than crashing', () {
      final failure = mapExceptionToFailure(
        _status(500, body: <Object, Object>{'message': 42}),
      );

      expect(failure.message, '42');
    });

    test('a body without a message keeps the default copy', () {
      expect(
        mapExceptionToFailure(_status(404, body: {'error': 'nope'})).message,
        'Data tidak ditemukan.',
      );
      expect(
        mapExceptionToFailure(_status(404, body: 'plain text')).message,
        'Data tidak ditemukan.',
      );
    });
  });

  group('non-Dio errors', () {
    test('a platform channel failure means secure storage is unreachable', () {
      expect(
        mapExceptionToFailure(PlatformException(code: 'keychain')),
        isA<StorageFailure>(),
      );
    });

    test('anything else is unexpected', () {
      expect(
        mapExceptionToFailure(StateError('boom')),
        isA<UnexpectedFailure>(),
      );
      expect(
        mapExceptionToFailure(const FormatException()),
        isA<UnexpectedFailure>(),
      );
    });
  });

  group('failureMessage', () {
    test('uses the failure message when the error is a Failure', () {
      expect(
        failureMessage(const NotFoundFailure(), fallback: 'fallback'),
        'Data tidak ditemukan.',
      );
    });

    test('falls back for a raw error or null', () {
      expect(
        failureMessage(StateError('boom'), fallback: 'fallback'),
        'fallback',
      );
      expect(failureMessage(null, fallback: 'fallback'), 'fallback');
    });
  });
}
