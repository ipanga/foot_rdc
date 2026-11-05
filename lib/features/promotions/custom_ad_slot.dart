import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import 'custom_ads.dart';

/// One FootRDC advertiser banner inside scrolling content: « PUBLICITÉ » above, the image at its own proportion, the
/// advertiser below. Nothing when there is no eligible ad, when the answer is not known yet, or when the image fails.
///
/// The ad is decided when the slot is first built. An answer that arrives later is used only while the slot is still
/// below the visible screen, so it never pushes the text the reader is looking at. A deliberate tap opens the
/// advertiser's HTTPS page in the system browser.
class CustomAdSlot extends ConsumerStatefulWidget {
  final AdPlacement placement;
  final EdgeInsets padding;

  /// Tests replace the browser.
  final Future<bool> Function(Uri url)? openLink;
  const CustomAdSlot({
    super.key,
    required this.placement,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.openLink,
  });

  @override
  ConsumerState<CustomAdSlot> createState() => _CustomAdSlotState();
}

/// Tests replace the network image (they have no image cache); [onError] is what a failed load calls.
@visibleForTesting
Widget Function(Uri image, Widget Function() onError)? customAdImageForTests;

class _CustomAdSlotState extends ConsumerState<CustomAdSlot> {
  CustomAd? _ad;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(customAdsProvider.notifier);
    _ad = ref.read(customAdsProvider).at(widget.placement, DateTime.now());
    // A screen with a slot is a good moment to refresh a stale answer, for the next screen.
    unawaited(notifier.refreshIfStale());
  }

  /// A broken image: the whole slot goes, after this frame.
  Widget _broken() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
    return const SizedBox.shrink();
  }

  Future<void> _open(CustomAd ad) async {
    final open = widget.openLink ?? (Uri u) => launchUrl(u, mode: LaunchMode.externalApplication);
    if (CustomAd.httpsLink(ad.link.toString()) == null) return;
    await open(ad.link);
  }

  /// A later answer: shown only when the slot has not been reached yet (its top is below the screen).
  void _lateAnswer(CustomAdsState next) {
    if (_ad != null || _failed || !mounted) return;
    final ad = next.at(widget.placement, DateTime.now());
    final box = context.findRenderObject();
    if (ad == null || box is! RenderBox || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top >= MediaQuery.sizeOf(context).height) setState(() => _ad = ad);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CustomAdsState>(customAdsProvider, (_, next) => _lateAnswer(next));
    final ad = _ad;
    if (ad == null || _failed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final radius = BorderRadius.circular(12);
    return Padding(
      key: ValueKey('custom-ad-${widget.placement.key}'),
      padding: widget.padding,
      child: Semantics(
        container: true,
        label: 'Publicité',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'PUBLICITÉ',
                  style: TextStyle(fontSize: 10.5, letterSpacing: 0.9, fontWeight: FontWeight.w700, color: muted),
                ),
              ),
            ),
            Semantics(
              button: true,
              link: true,
              label: '${ad.alt}. Ouvre le site de l’annonceur dans le navigateur.',
              excludeSemantics: true,
              onTap: () => _open(ad),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: radius,
                  onTap: () => _open(ad),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      // Space reserved at the image's proportion before it loads: nothing below moves.
                      child: AspectRatio(
                        aspectRatio: ad.aspectRatio,
                        child:
                            customAdImageForTests?.call(ad.image, _broken) ??
                            CachedNetworkImage(
                              imageUrl: ad.image.toString(),
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 150),
                              placeholder: (_, _) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                              errorWidget: (_, _, _) => _broken(),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (ad.advertiser.isNotEmpty)
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    ad.advertiser,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Splits an article body after its introduction: after the [paragraphs]-th paragraph, when at least [after]
/// top-level blocks follow (otherwise null: a short article gets no ad in its text, the end banner is enough).
(String, String)? splitAfterIntroduction(String html, {int paragraphs = 2, int after = 3}) {
  final fragment = html_parser.parseFragment(html);
  final nodes = fragment.nodes.where((n) => n is! dom.Text || n.text.trim().isNotEmpty).toList();
  var seen = 0;
  for (var i = 0; i < nodes.length; i++) {
    final n = nodes[i];
    if (n is dom.Element && n.localName == 'p' && n.text.trim().isNotEmpty) seen++;
    if (seen == paragraphs) {
      if (nodes.length - i - 1 < after) return null;
      String join(Iterable<dom.Node> list) =>
          list.map((x) => x is dom.Element ? x.outerHtml : (x is dom.Text ? x.text : '')).join();
      return (join(nodes.take(i + 1)), join(nodes.skip(i + 1)));
    }
  }
  return null;
}
