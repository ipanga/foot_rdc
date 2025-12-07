import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Provider for HTTP client used across the application
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});
