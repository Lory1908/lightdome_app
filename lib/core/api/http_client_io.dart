import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String> getText(String url, {Duration timeout = const Duration(seconds: 2)}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final req = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final resp = await req.close().timeout(timeout);
    final body = await resp.transform(utf8.decoder).join().timeout(timeout);
    return body;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>> getJson(String url, {Duration timeout = const Duration(seconds: 2)}) async {
  final text = await getText(url, timeout: timeout);
  return jsonDecode(text) as Map<String, dynamic>;
}

Future<String> postJson(String url, Map<String, dynamic> body,
    {Duration timeout = const Duration(seconds: 2)}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final req = await client.postUrl(Uri.parse(url)).timeout(timeout);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    req.add(utf8.encode(jsonEncode(body)));
    final resp = await req.close().timeout(timeout);
    return await resp.transform(utf8.decoder).join().timeout(timeout);
  } finally {
    client.close();
  }
}

Future<String> postBytes(String url, List<int> bytes,
    {Duration timeout = const Duration(seconds: 4),
    Map<String, String>? headers}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final req = await client.postUrl(Uri.parse(url)).timeout(timeout);
    headers?.forEach(req.headers.set);
    req.add(bytes);
    final resp = await req.close().timeout(timeout);
    return await resp.transform(utf8.decoder).join().timeout(timeout);
  } finally {
    client.close();
  }
}

Future<String> deleteText(String url, {Duration timeout = const Duration(seconds: 2)}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final req = await client.deleteUrl(Uri.parse(url)).timeout(timeout);
    final resp = await req.close().timeout(timeout);
    return await resp.transform(utf8.decoder).join().timeout(timeout);
  } finally {
    client.close();
  }
}

Future<String> postStream(String url, Stream<List<int>> data,
    {Duration timeout = const Duration(seconds: 10),
    Map<String, String>? headers,
    int? contentLength,
    void Function(int sent, int total)? onProgress}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final req = await client.postUrl(Uri.parse(url)).timeout(timeout);
    headers?.forEach(req.headers.set);
    if (contentLength != null) {
      req.headers.set(HttpHeaders.contentLengthHeader, contentLength);
    }
    var sent = 0;
    final monitored = data.transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (chunk, sink) {
        sent += chunk.length;
        sink.add(chunk);
        if (onProgress != null) {
          onProgress(sent, contentLength ?? sent);
        }
      },
      handleError: (error, stackTrace, sink) => sink.addError(error, stackTrace),
      handleDone: (sink) => sink.close(),
    ));
    await req.addStream(monitored).timeout(timeout);
    final resp = await req.close().timeout(timeout);
    final body = await resp.transform(utf8.decoder).join().timeout(timeout);
    return body;
  } finally {
    client.close();
  }
}
