import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/painting.dart';

// Repeatable image rendering from actual public CDN logos, with no test HTTP.
void useFixtureLogos() {
  final data =
      jsonDecode(File('test/fixtures/public_logos.json').readAsStringSync())
          as Map;
  final images = {
    for (final entry in data.entries)
      entry.key.toString(): base64Decode(entry.value as String),
  };
  debugNetworkImageHttpClientProvider = () => _ImageClient(images);
}

class _ImageClient implements HttpClient {
  final Map<String, List<int>> images;
  _ImageClient(this.images);
  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _ImageRequest(images[url.toString()]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageRequest implements HttpClientRequest {
  final List<int>? bytes;
  _ImageRequest(this.bytes);
  @override
  Future<HttpClientResponse> close() async => _ImageResponse(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int>? bytes;
  _ImageResponse(this.bytes);
  @override
  int get statusCode => bytes == null ? 404 : 200;
  @override
  int get contentLength => bytes?.length ?? 0;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.value(bytes ?? <int>[]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
