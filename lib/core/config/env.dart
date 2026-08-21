import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class Env {
  static String get apiBaseUrl {
    final value = dotenv.env['APP_API_BASE_URL']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('APP_API_BASE_URL is missing from .env');
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError('APP_API_BASE_URL must contain a valid API base URL');
    }
  }
}
