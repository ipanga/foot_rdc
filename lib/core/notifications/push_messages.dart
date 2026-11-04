import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../navigation/deep_link_handler.dart';

/// Messenger used for in-app notification banners.
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// The article or match on screen (`footrdc://article/12`, `footrdc://match/34`), set by those screens.
/// A notification about it while it is open is not shown again.
final currentContentLink = ValueNotifier<String?>(null);

/// Marks [link] as the content on screen for as long as the returned callback is not called.
VoidCallback showingContent(String link) {
  currentContentLink.value = link;
  return () {
    if (currentContentLink.value == link) currentContentLink.value = null;
  };
}

String? pushLink(RemoteMessage message) {
  final link = message.data['link'];
  return link is String && link.startsWith('footrdc://') ? link : null;
}

/// Foreground: an in-app banner (the system shows nothing then, so there is no duplicate). Taps from the
/// background or a terminated app: the notification's native link.
Future<void> setUpPushMessaging() async {
  if (Firebase.apps.isEmpty) return;
  final fm = FirebaseMessaging.instance;
  // iOS: no system banner while the app is open; Android never shows one in the foreground for FCM messages.
  await fm.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false);
  FirebaseMessaging.onMessage.listen(showForegroundNotification);
  FirebaseMessaging.onMessageOpenedApp.listen((m) {
    final link = pushLink(m);
    if (link != null) pushLinks.add(link);
  });
  final initial = await fm.getInitialMessage();
  final link = initial == null ? null : pushLink(initial);
  if (link != null) {
    // After the first frame, once the navigator and the link handler exist.
    WidgetsBinding.instance.addPostFrameCallback((_) => pushLinks.add(link));
  }
}

@visibleForTesting
void showForegroundNotification(RemoteMessage message) {
  final link = pushLink(message);
  final n = message.notification;
  if (n == null || (link != null && link == currentContentLink.value)) return;
  showNotificationBanner(title: n.title ?? 'FootRDC', body: n.body ?? '', link: link);
}

void showNotificationBanner({required String title, required String body, String? link}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('push-banner'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (body.isNotEmpty) Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        action: link == null ? null : SnackBarAction(label: 'Ouvrir', onPressed: () => pushLinks.add(link)),
      ),
    );
}

/// Marks [link] as the content on screen while this widget is mounted.
class ContentLinkScope extends StatefulWidget {
  final String link;
  final Widget child;
  const ContentLinkScope({super.key, required this.link, required this.child});
  @override
  State<ContentLinkScope> createState() => _ContentLinkScopeState();
}

class _ContentLinkScopeState extends State<ContentLinkScope> {
  late VoidCallback _release;

  @override
  void initState() {
    super.initState();
    _release = showingContent(widget.link);
  }

  @override
  void didUpdateWidget(ContentLinkScope old) {
    super.didUpdateWidget(old);
    if (old.link != widget.link) {
      _release();
      _release = showingContent(widget.link);
    }
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
