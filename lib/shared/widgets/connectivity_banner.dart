import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/network/connectivity_service.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/shared/providers/connectivity_provider.dart';

/// Slim animated banner shown above the bottom navigation when the device
/// is offline. On the offline → online transition it briefly displays a
/// green "Connexion rétablie" confirmation (~2s) before collapsing.
///
/// Designed to live inside [Scaffold.bottomNavigationBar] (or any
/// fixed-width vertical slot) — its height animates between 0 and ~32 dp
/// so the surrounding layout stays stable.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() =>
      _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  static const Duration _restoredDisplay = Duration(seconds: 2);
  static const double _height = 32;

  bool _wasOffline = false;
  bool _showRestored = false;
  Timer? _restoredTimer;

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  void _onStatusChange(ConnectivityStatus status) {
    if (status == ConnectivityStatus.disconnected) {
      _restoredTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _wasOffline = true;
        _showRestored = false;
      });
    } else if (status == ConnectivityStatus.connected && _wasOffline) {
      _restoredTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _wasOffline = false;
        _showRestored = true;
      });
      _restoredTimer = Timer(_restoredDisplay, () {
        if (!mounted) return;
        setState(() => _showRestored = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConnectivityStatus>>(
      connectivityStatusProvider,
      (prev, next) => next.whenData(_onStatusChange),
    );

    final status = ref.watch(connectivityStatusProvider).valueOrNull;
    final isOffline = status == ConnectivityStatus.disconnected;
    final visible = isOffline || _showRestored;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: visible ? _height : 0,
      color: isOffline ? AppColors.error : AppColors.success,
      child: visible
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOffline
                        ? 'Pas de connexion internet'
                        : 'Connexion rétablie',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
