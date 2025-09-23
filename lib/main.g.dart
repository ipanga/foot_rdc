// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fetchArticlesHash() => r'050304a0aa1dff0bf2af401571bcc958991e39d8';

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

/// See also [fetchArticles].
@ProviderFor(fetchArticles)
const fetchArticlesProvider = FetchArticlesFamily();

/// See also [fetchArticles].
class FetchArticlesFamily extends Family<AsyncValue<List<Article>>> {
  /// See also [fetchArticles].
  const FetchArticlesFamily();

  /// See also [fetchArticles].
  FetchArticlesProvider call(
    String input,
  ) {
    return FetchArticlesProvider(
      input,
    );
  }

  @override
  FetchArticlesProvider getProviderOverride(
    covariant FetchArticlesProvider provider,
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
  String? get name => r'fetchArticlesProvider';
}

/// See also [fetchArticles].
class FetchArticlesProvider extends AutoDisposeFutureProvider<List<Article>> {
  /// See also [fetchArticles].
  FetchArticlesProvider(
    String input,
  ) : this._internal(
          (ref) => fetchArticles(
            ref as FetchArticlesRef,
            input,
          ),
          from: fetchArticlesProvider,
          name: r'fetchArticlesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fetchArticlesHash,
          dependencies: FetchArticlesFamily._dependencies,
          allTransitiveDependencies:
              FetchArticlesFamily._allTransitiveDependencies,
          input: input,
        );

  FetchArticlesProvider._internal(
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
    FutureOr<List<Article>> Function(FetchArticlesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FetchArticlesProvider._internal(
        (ref) => create(ref as FetchArticlesRef),
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
  AutoDisposeFutureProviderElement<List<Article>> createElement() {
    return _FetchArticlesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchArticlesProvider && other.input == input;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, input.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FetchArticlesRef on AutoDisposeFutureProviderRef<List<Article>> {
  /// The parameter `input` of this provider.
  String get input;
}

class _FetchArticlesProviderElement
    extends AutoDisposeFutureProviderElement<List<Article>>
    with FetchArticlesRef {
  _FetchArticlesProviderElement(super.provider);

  @override
  String get input => (origin as FetchArticlesProvider).input;
}

String _$searchArticlesHash() => r'da4194cd89a0ba286edb24b48288e04bc25446b6';

/// See also [searchArticles].
@ProviderFor(searchArticles)
const searchArticlesProvider = SearchArticlesFamily();

/// See also [searchArticles].
class SearchArticlesFamily extends Family<AsyncValue<List<Article>>> {
  /// See also [searchArticles].
  const SearchArticlesFamily();

  /// See also [searchArticles].
  SearchArticlesProvider call(
    String searchName,
  ) {
    return SearchArticlesProvider(
      searchName,
    );
  }

  @override
  SearchArticlesProvider getProviderOverride(
    covariant SearchArticlesProvider provider,
  ) {
    return call(
      provider.searchName,
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
  String? get name => r'searchArticlesProvider';
}

/// See also [searchArticles].
class SearchArticlesProvider extends AutoDisposeFutureProvider<List<Article>> {
  /// See also [searchArticles].
  SearchArticlesProvider(
    String searchName,
  ) : this._internal(
          (ref) => searchArticles(
            ref as SearchArticlesRef,
            searchName,
          ),
          from: searchArticlesProvider,
          name: r'searchArticlesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$searchArticlesHash,
          dependencies: SearchArticlesFamily._dependencies,
          allTransitiveDependencies:
              SearchArticlesFamily._allTransitiveDependencies,
          searchName: searchName,
        );

  SearchArticlesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.searchName,
  }) : super.internal();

  final String searchName;

  @override
  Override overrideWith(
    FutureOr<List<Article>> Function(SearchArticlesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SearchArticlesProvider._internal(
        (ref) => create(ref as SearchArticlesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        searchName: searchName,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Article>> createElement() {
    return _SearchArticlesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SearchArticlesProvider && other.searchName == searchName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, searchName.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SearchArticlesRef on AutoDisposeFutureProviderRef<List<Article>> {
  /// The parameter `searchName` of this provider.
  String get searchName;
}

class _SearchArticlesProviderElement
    extends AutoDisposeFutureProviderElement<List<Article>>
    with SearchArticlesRef {
  _SearchArticlesProviderElement(super.provider);

  @override
  String get searchName => (origin as SearchArticlesProvider).searchName;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
