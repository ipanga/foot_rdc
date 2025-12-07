// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchMatchesHash() => r'd5bbf290a40f37662fd2f41c2379910675acc8c6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Fetches matches from the SportsPress API
///
/// Copied from [fetchMatches].
@ProviderFor(fetchMatches)
const fetchMatchesProvider = FetchMatchesFamily();

/// Fetches matches from the SportsPress API
///
/// Copied from [fetchMatches].
class FetchMatchesFamily extends Family<AsyncValue<List<Match>>> {
  /// Fetches matches from the SportsPress API
  ///
  /// Copied from [fetchMatches].
  const FetchMatchesFamily();

  /// Fetches matches from the SportsPress API
  ///
  /// Copied from [fetchMatches].
  FetchMatchesProvider call(
    String input,
  ) {
    return FetchMatchesProvider(
      input,
    );
  }

  @override
  FetchMatchesProvider getProviderOverride(
    covariant FetchMatchesProvider provider,
  ) {
    return call(
      provider.input,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchMatchesProvider';
}

/// Fetches matches from the SportsPress API
///
/// Copied from [fetchMatches].
class FetchMatchesProvider extends AutoDisposeFutureProvider<List<Match>> {
  /// Fetches matches from the SportsPress API
  ///
  /// Copied from [fetchMatches].
  FetchMatchesProvider(
    String input,
  ) : this._internal(
          (ref) => fetchMatches(
            ref as FetchMatchesRef,
            input,
          ),
          from: fetchMatchesProvider,
          name: r'fetchMatchesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fetchMatchesHash,
          dependencies: FetchMatchesFamily._dependencies,
          allTransitiveDependencies:
              FetchMatchesFamily._allTransitiveDependencies,
          input: input,
        );

  FetchMatchesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.input,
  }) : super.internal();

  final String input;

  @override
  Override overrideWith(
    FutureOr<List<Match>> Function(FetchMatchesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchMatchesProvider._internal(
        (ref) => create(ref as FetchMatchesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        input: input,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Match>> createElement() {
    return _FetchMatchesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchMatchesProvider && other.input == input;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, input.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FetchMatchesRef on AutoDisposeFutureProviderRef<List<Match>> {
  /// The parameter `input` of this provider.
  String get input;
}

class _FetchMatchesProviderElement
    extends AutoDisposeFutureProviderElement<List<Match>> with FetchMatchesRef {
  _FetchMatchesProviderElement(super.provider);

  @override
  String get input => (origin as FetchMatchesProvider).input;
}

String _$fetchMatchesByLeagueHash() =>
    r'f559cfba9f9080f7615d5f9832c09f9b4f270ba6';

/// Fetches matches for a specific league group
///
/// Copied from [fetchMatchesByLeague].
@ProviderFor(fetchMatchesByLeague)
const fetchMatchesByLeagueProvider = FetchMatchesByLeagueFamily();

/// Fetches matches for a specific league group
///
/// Copied from [fetchMatchesByLeague].
class FetchMatchesByLeagueFamily extends Family<AsyncValue<List<Match>>> {
  /// Fetches matches for a specific league group
  ///
  /// Copied from [fetchMatchesByLeague].
  const FetchMatchesByLeagueFamily();

  /// Fetches matches for a specific league group
  ///
  /// Copied from [fetchMatchesByLeague].
  FetchMatchesByLeagueProvider call({
    required int leagueId,
    required int seasonId,
    required int page,
    required int perPage,
  }) {
    return FetchMatchesByLeagueProvider(
      leagueId: leagueId,
      seasonId: seasonId,
      page: page,
      perPage: perPage,
    );
  }

  @override
  FetchMatchesByLeagueProvider getProviderOverride(
    covariant FetchMatchesByLeagueProvider provider,
  ) {
    return call(
      leagueId: provider.leagueId,
      seasonId: provider.seasonId,
      page: provider.page,
      perPage: provider.perPage,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fetchMatchesByLeagueProvider';
}

/// Fetches matches for a specific league group
///
/// Copied from [fetchMatchesByLeague].
class FetchMatchesByLeagueProvider
    extends AutoDisposeFutureProvider<List<Match>> {
  /// Fetches matches for a specific league group
  ///
  /// Copied from [fetchMatchesByLeague].
  FetchMatchesByLeagueProvider({
    required int leagueId,
    required int seasonId,
    required int page,
    required int perPage,
  }) : this._internal(
          (ref) => fetchMatchesByLeague(
            ref as FetchMatchesByLeagueRef,
            leagueId: leagueId,
            seasonId: seasonId,
            page: page,
            perPage: perPage,
          ),
          from: fetchMatchesByLeagueProvider,
          name: r'fetchMatchesByLeagueProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fetchMatchesByLeagueHash,
          dependencies: FetchMatchesByLeagueFamily._dependencies,
          allTransitiveDependencies:
              FetchMatchesByLeagueFamily._allTransitiveDependencies,
          leagueId: leagueId,
          seasonId: seasonId,
          page: page,
          perPage: perPage,
        );

  FetchMatchesByLeagueProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.leagueId,
    required this.seasonId,
    required this.page,
    required this.perPage,
  }) : super.internal();

  final int leagueId;
  final int seasonId;
  final int page;
  final int perPage;

  @override
  Override overrideWith(
    FutureOr<List<Match>> Function(FetchMatchesByLeagueRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchMatchesByLeagueProvider._internal(
        (ref) => create(ref as FetchMatchesByLeagueRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        leagueId: leagueId,
        seasonId: seasonId,
        page: page,
        perPage: perPage,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Match>> createElement() {
    return _FetchMatchesByLeagueProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchMatchesByLeagueProvider &&
        other.leagueId == leagueId &&
        other.seasonId == seasonId &&
        other.page == page &&
        other.perPage == perPage;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, leagueId.hashCode);
    hash = _SystemHash.combine(hash, seasonId.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);
    hash = _SystemHash.combine(hash, perPage.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FetchMatchesByLeagueRef on AutoDisposeFutureProviderRef<List<Match>> {
  /// The parameter `leagueId` of this provider.
  int get leagueId;

  /// The parameter `seasonId` of this provider.
  int get seasonId;

  /// The parameter `page` of this provider.
  int get page;

  /// The parameter `perPage` of this provider.
  int get perPage;
}

class _FetchMatchesByLeagueProviderElement
    extends AutoDisposeFutureProviderElement<List<Match>>
    with FetchMatchesByLeagueRef {
  _FetchMatchesByLeagueProviderElement(super.provider);

  @override
  int get leagueId => (origin as FetchMatchesByLeagueProvider).leagueId;
  @override
  int get seasonId => (origin as FetchMatchesByLeagueProvider).seasonId;
  @override
  int get page => (origin as FetchMatchesByLeagueProvider).page;
  @override
  int get perPage => (origin as FetchMatchesByLeagueProvider).perPage;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
