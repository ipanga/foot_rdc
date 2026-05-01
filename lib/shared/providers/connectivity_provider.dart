import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/network/connectivity_service.dart';

/// Singleton [ConnectivityService] for the app.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Global stream of [ConnectivityStatus]. Emits the current status on
/// subscription, then re-emits on every OS-level interface change.
///
/// Only one OS subscription exists app-wide (Riverpod dedupes the
/// underlying stream); UI consumers can `ref.watch` or `ref.listen` freely.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  return ref.watch(connectivityServiceProvider).statusStream();
});
