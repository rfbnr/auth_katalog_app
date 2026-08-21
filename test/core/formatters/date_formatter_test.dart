import 'package:auth_katalog_app/core/formatters/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats ISO dates as Indonesian long form', () {
    expect(DateFormatter.longDate('1996-05-30'), '30 Mei 1996');
  });

  test('formats the boundary months', () {
    expect(DateFormatter.longDate('2001-01-01'), '1 Januari 2001');
    expect(DateFormatter.longDate('2001-12-31'), '31 Desember 2001');
  });

  test('accepts the full timestamp form the API may return', () {
    expect(DateFormatter.longDate('1996-05-30T00:00:00.000Z'), '30 Mei 1996');
  });

  test('returns null for absent or unparseable input', () {
    expect(DateFormatter.longDate(null), isNull);
    expect(DateFormatter.longDate(''), isNull);
    expect(DateFormatter.longDate('not a date'), isNull);
  });
}
