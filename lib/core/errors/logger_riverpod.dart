import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoggerRiverpod extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {}

  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {}

  @override
  void didDisposeProvider(ProviderBase provider, ProviderContainer container) {}
}
