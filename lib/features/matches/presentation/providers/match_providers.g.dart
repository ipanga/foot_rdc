// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchMatchesHash() => r'm1a2t3c4h5e6s7h8a9s0h';

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
    extends AutoDisposeFutureProviderElement<List<Match>>
    with FetchMatchesRef {
  _FetchMatchesProviderElement(super.provider);

  @override
  String get input => (origin as FetchMatchesProvider).input;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}
