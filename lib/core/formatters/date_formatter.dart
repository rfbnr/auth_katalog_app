abstract final class DateFormatter {
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String? longDate(String? isoDate) {
    if (isoDate == null) return null;
    final parsed = DateTime.tryParse(isoDate.trim());
    if (parsed == null) return null;

    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }
}
