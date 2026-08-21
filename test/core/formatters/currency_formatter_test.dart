import 'package:auth_katalog_app/core/formatters/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats prices as Rupiah with Indonesian thousands separator', () {
    expect(CurrencyFormatter.rupiah(1250000), 'Rp1.250.000');
  });
}
