import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/football_api.dart';
import '../domain/football_models.dart';
import 'football_providers.dart';
import 'football_strings.dart';

class FootballLogo extends StatelessWidget {
  final String url;
  final double size;
  const FootballLogo(this.url, {this.size = 36, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Uri.tryParse(url)?.scheme == 'https'
        ? Image.network(
            url,
            fit: BoxFit.contain,
            cacheWidth: (size * 3).round(),
            errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : const Icon(Icons.shield_outlined),
          )
        : const Icon(Icons.shield_outlined),
  );
}

class FootballEmpty extends StatelessWidget {
  final String label;
  final VoidCallback? retry;
  const FootballEmpty(this.label, {this.retry, super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sports_soccer_outlined, size: 32),
        const SizedBox(height: 12),
        Text(label, textAlign: TextAlign.center),
        if (retry != null)
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: Text(FootballStrings.of(context).t('retry')),
          ),
      ],
    ),
  );
}

String footballError(BuildContext context, Object error) =>
    FootballStrings.of(context).t(
      error is FootballFailure && error.code == 'unavailable'
          ? 'unavailable'
          : 'error',
    );

class FootballMatchTile extends ConsumerWidget {
  final FootballRecord match;
  const FootballMatchTile(this.match, {super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = FootballStrings.of(context);
    final teams =
        match.text('home_name').isEmpty || match.text('away_name').isEmpty
        ? {
            for (final team
                in ref.watch(footballDirectoryProvider).valueOrNull?.rows ??
                    <FootballRecord>[])
              team.id: team,
          }
        : <int, FootballRecord>{};
    final home = teams[match.number('home_team_id')];
    final away = teams[match.number('away_team_id')];
    final live = ref.watch(footballConfigProvider)?.live.enabled ?? false;
    final homeName = match.text('home_name').isNotEmpty
        ? match.text('home_name')
        : home?.name ?? strings.t('teams');
    final awayName = match.text('away_name').isNotEmpty
        ? match.text('away_name')
        : away?.name ?? strings.t('teams');
    return Semantics(
      button: true,
      label: '$homeName, $awayName',
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pushNamed('/football/match/${match.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.kickoff == null
                          ? ''
                          : DateFormat(
                              'EEE d MMM · HH:mm',
                              strings.language,
                            ).format(match.kickoff!.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      match.isLive && !live
                          ? strings.t('livePending')
                          : strings.status(match.status),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FootballLogo(
                    match.text('home_logo').isNotEmpty
                        ? match.text('home_logo')
                        : home?.text('logo_url') ?? '',
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(homeName, maxLines: 3)),
                  SizedBox(
                    width: 76,
                    child: Text(
                      match.score(liveAllowed: live),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      awayName,
                      textAlign: TextAlign.end,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FootballLogo(
                    match.text('away_logo').isNotEmpty
                        ? match.text('away_logo')
                        : away?.text('logo_url') ?? '',
                  ),
                ],
              ),
              if (match.text('venue').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    match.text('venue'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (match.data['quality'] is Map &&
                  (match.data['quality'] as Map)['publishable'] != true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    strings.t('unverified'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class FootballList extends ConsumerStatefulWidget {
  final FootballQuery query;
  final String empty;
  final Widget Function(BuildContext, FootballRecord) row;
  final List<Widget> header;
  final bool embedded;
  final bool paginate;
  final String Function(FootballRecord)? group;
  const FootballList({
    required this.query,
    required this.row,
    this.empty = 'empty',
    this.header = const [],
    this.embedded = false,
    this.paginate = true,
    this.group,
    super.key,
  });
  @override
  ConsumerState<FootballList> createState() => _FootballListState();
}

class _FootballListState extends ConsumerState<FootballList> {
  final List<FootballRecord> _rows = [];
  bool _loading = true, _more = false, _cached = false;
  int _page = 0, _generation = 0;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void didUpdateWidget(FootballList old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) _load(reset: true);
  }

  Future<void> _load({bool reset = false, bool refresh = false}) async {
    final token = reset ? ++_generation : _generation;
    final page = reset ? 1 : _page + 1;
    if (reset) {
      _page = 0;
      _more = false;
      if (!refresh) {
        _rows.clear();
        _cached = false;
      }
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final repository = await ref.read(footballRepositoryProvider.future);
      final result = await repository.page(
        FootballQuery(widget.query.path, {
          ...widget.query.filters,
          'page': page,
          'limit': widget.query.filters['limit'] ?? 25,
        }),
        refresh: refresh,
      );
      if (!mounted || token != _generation) return;
      setState(() {
        if (reset) _rows.clear();
        final ids = _rows.map((row) => row.id).toSet();
        _rows.addAll(result.rows.where((row) => ids.add(row.id)));
        if (widget.group != null) {
          _rows.sort((a, b) => widget.group!(a).compareTo(widget.group!(b)));
        }
        _page = page;
        _more = result.hasMore;
        _cached = result.cached;
        _loading = false;
      });
    } catch (error) {
      if (mounted && token == _generation) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = FootballStrings.of(context);
    final children = <Widget>[
      ...widget.header,
      if (_cached)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(strings.t('cached'), textAlign: TextAlign.center),
        ),
      if (!_loading && _rows.isEmpty && _error == null)
        FootballEmpty(strings.t(widget.empty)),
      for (var index = 0; index < _rows.length; index++) ...[
        if (widget.group != null &&
            (index == 0 ||
                widget.group!(_rows[index]) != widget.group!(_rows[index - 1])))
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.group!(_rows[index])),
          ),
        Builder(
          builder: (context) => KeyedSubtree(
            key: ValueKey('${widget.query.path}:${_rows[index].id}'),
            child: widget.row(context, _rows[index]),
          ),
        ),
        const Divider(height: 1),
      ],
      if (_loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (_error != null)
        FootballEmpty(
          footballError(context, _error!),
          retry: () => _load(reset: _page == 0, refresh: true),
        ),
      if (widget.paginate && _more && !_loading && _error == null)
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.expand_more),
          label: Text(strings.t('more')),
        ),
      const SizedBox(height: 16),
    ];
    final list = ListView.builder(
      shrinkWrap: widget.embedded,
      physics: widget.embedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (_, index) => children[index],
    );
    return widget.embedded
        ? list
        : RefreshIndicator(
            onRefresh: () => _load(reset: true, refresh: true),
            child: list,
          );
  }
}

class FootballMetrics extends StatelessWidget {
  final Map<String, num> metrics;
  const FootballMetrics(this.metrics, {super.key});
  @override
  Widget build(BuildContext context) {
    final strings = FootballStrings.of(context);
    if (metrics.isEmpty) return FootballEmpty(strings.t('empty'));
    return Column(
      children: [
        for (final entry in metrics.entries)
          ListTile(
            dense: true,
            title: Text(strings.metric(entry.key)),
            trailing: Text(
              NumberFormat.decimalPattern(strings.language).format(entry.value),
            ),
          ),
      ],
    );
  }
}
