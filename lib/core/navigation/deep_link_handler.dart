import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/football/presentation/screens/club_detail_screen.dart';
import '../../features/home/presentation/app_tabs.dart';
import '../../features/football/presentation/screens/match_detail_screen.dart';
import '../../features/news/domain/entities/article.dart';
import '../../features/news/presentation/screens/article_detail_screen.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import 'deep_links.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

/// Links from push notifications; app links arrive through [AppLinks].
final pushLinks = StreamController<String>.broadcast();

/// Opens links on the root navigator. A link to something deleted shows a short message, never a broken page.
class DeepLinkHandler extends ConsumerStatefulWidget {
  final Widget child;
  const DeepLinkHandler({super.key, required this.child});
  @override
  ConsumerState<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends ConsumerState<DeepLinkHandler> {
  final _subscriptions = <StreamSubscription<dynamic>>[];

  @override
  void initState() {
    super.initState();
    _subscriptions.add(pushLinks.stream.listen(_open));
    try {
      final links = AppLinks();
      _subscriptions.add(links.uriLinkStream.listen((uri) => _open(uri.toString()), onError: (_) {}));
    } catch (_) {
      // Links are optional: the app works without them.
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<Article?> _article(Map<String, dynamic> query, [String path = '']) async {
    final response = await ref
        .read(dioClientProvider)
        .get<dynamic>('${ApiConstants.wpApiPath}/posts$path', queryParameters: {'_embed': true, ...query});
    final data = response.data;
    if (data is Map<String, dynamic> && data['id'] != null) return Article.fromJson(data);
    if (data is List && data.isNotEmpty) return Article.fromJson(Map<String, dynamic>.from(data.first as Map));
    return null;
  }

  Future<void> _open(String raw) async {
    final link = DeepLink.parse(raw);
    final navigator = appNavigatorKey.currentState;
    if (link == null || navigator == null) return;
    void push(Widget page) => navigator.push(MaterialPageRoute<void>(builder: (_) => page));
    switch (link) {
      case MatchLink(:final id):
        push(MatchDetailScreen(matchId: id));
      case ClubLink(:final id):
        push(ClubDetailScreen(clubId: id));
      case LinafootLink():
        // Linafoot and standings links open the Classement tab.
        navigator.popUntil((route) => route.isFirst);
        ref.read(currentTabProvider.notifier).state = AppTab.classement;
      case ArticleLink(:final id):
        await _openArticle(() => _article(const {}, '/$id'), push);
      case ArticleSlugLink(:final slug):
        await _openArticle(() => _article({'slug': slug}), push);
    }
  }

  Future<void> _openArticle(Future<Article?> Function() load, void Function(Widget) push) async {
    Article? article;
    try {
      article = await load();
    } catch (_) {
      article = null;
    }
    if (article != null) {
      push(ArticleDetailScreen(article: article));
    } else {
      final context = appNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text('Cet article n’est plus disponible.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
