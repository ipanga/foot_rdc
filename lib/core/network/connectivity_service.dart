import 'package:connectivity_plus/connectivity_plus.dart';

/// Binary online/offline status. Mapped from connectivity_plus' richer
/// per-interface results. We intentionally don't model "reconnecting" or
/// "slow" here — the package reports network *interface* state (wifi /
/// mobile / none), not real reachability, and active reachability probing
/// is out of scope for this iteration.
enum ConnectivityStatus { connected, disconnected }

/// Thin wrapper around `connectivity_plus` exposing a [ConnectivityStatus]
/// stream. A device counts as `connected` if at least one interface is up
/// (wifi, mobile, ethernet, vpn, bluetooth, or other) — this matches what
/// most users mean by "online", even though it doesn't guarantee actual
/// reachability (captive portals, DNS issues, etc. would still report
/// connected here).
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  Future<ConnectivityStatus> currentStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _statusFor(results);
  }

  /// Emits the current status once, then re-emits on every interface
  /// change. `distinct()` ensures consecutive duplicates are filtered (e.g.
  /// switching from wifi to wifi+mobile while still online won't fire).
  Stream<ConnectivityStatus> statusStream() async* {
    yield await currentStatus();
    yield* _connectivity.onConnectivityChanged
        .map(_statusFor)
        .distinct();
  }

  ConnectivityStatus _statusFor(List<ConnectivityResult> results) {
    final hasNetwork =
        results.any((r) => r != ConnectivityResult.none);
    return hasNetwork
        ? ConnectivityStatus.connected
        : ConnectivityStatus.disconnected;
  }
}
