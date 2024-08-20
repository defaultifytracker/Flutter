import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'package:flutter/foundation.dart';

import 'defaultify_plugin.dart';
import 'launch_option.dart';
import 'package:uuid/uuid.dart';

const Uuid _globalUuid = Uuid();

Future<NetworkLoggerHttpClientRequest> _wrapRequest(
    Future<HttpClientRequest> request) async {
  var timestamp = DateTime.now().millisecondsSinceEpoch;

  return request.then((actualRequest) {
    if (actualRequest is NetworkLoggerHttpClientRequest) {
      return request as Future<NetworkLoggerHttpClientRequest>;
    }

    return Future.value(
        NetworkLoggerHttpClientRequest(actualRequest, timestamp));
  });
}

_wrapResponse(HttpClientResponse response, String requestID, String originalUrl,
    String originalMethod, int timestamp, String? requestbody,
    {Map<String, String>? requestHeaders}) {
  if (response is NetworkLoggerHttpClientRequest) {
    return response;
  }
  // Provide a default value for requestbody if it is null
  final nonNullableRequestbody = requestbody ?? ''; // Provide default value
  // Ensure requestHeaders is non-null by providing an empty map if it is null
  final nonNullableRequestHeaders = requestHeaders ?? <String, String>{};

  return NetworkLoggerHttpClientResponse(
      response,
      requestID,
      originalUrl,
      originalMethod,
      timestamp,
      nonNullableRequestbody,
      nonNullableRequestHeaders);
}

void _registerCompleteEvent(NetworkLoggerHttpClientResponse response,
    [String? noBodyReason,
      String? body,
      String? requestbody,
      Map<String, String>? requestHeaders,
      int? timestamp]) {
  var isError = response.statusCode >= 400;
  var eventData = <String, dynamic>{
    'id': response.requestID,
    'timestamp': timestamp ?? response.timestamp,
    'url': response.originalUrl,
    'method': response.originalMethod,
    'type': isError ? 'error' : 'complete',
    'size': body?.length ?? response.contentLength,
    'status': response.statusCode,
    'isSupplement': noBodyReason != null || body != null,
  };

  if (noBodyReason != null) {
    eventData['noBodyReason'] = noBodyReason;
  } else if (body != null) {
    eventData['body'] = body;
  }

  if (isError) {
    eventData['error'] = response.reasonPhrase;
  }
  if (requestbody != null) {
    eventData['requestPayload'] = requestbody;
  }

  if (response.isRedirect) {
    eventData['redirectUrl'] = response.redirects.last.location.toString();
  }
  eventData['headers'] = requestHeaders;

  dynamic headers = <String, dynamic>{};
  response.headers.forEach((name, values) {
    headers[name] = values.join(', ');
  });

  eventData['responseHeaders'] = headers;
  try {
    DefaultifyPlugin.registerNetworkEvent(eventData);
  } catch (e) {
    if (kDebugMode) {
      print('Error registering network event: $e');
    }
  }
}

class NetworkLoggerHttpClientResponse implements HttpClientResponse {
  final HttpClientResponse _inner;
  final String requestID;
  final String originalUrl;
  final String originalMethod;
  final int timestamp;
  Stream<List<int>>? _wrapperStream;
  StringBuffer? _receiveBuffer = StringBuffer();

  final String requestbody;
  final Map<String, String> requestHeaders;

  NetworkLoggerHttpClientResponse(
      this._inner,
      this.requestID,
      this.originalUrl,
      this.originalMethod,
      this.timestamp,
      this.requestbody,
      this.requestHeaders) {
    _wrapperStream = _readAndRecreateStream(_inner);
  }

  Stream<List<int>> _readAndRecreateStream(Stream<List<int>> source) async* {
    await for (var chunk in source) {
      _addItems(chunk);
      yield chunk;
    }
    _readResponseBody(this, requestbody, requestHeaders, timestamp);
  }

  void _addItems(List<int> data) {
    if (headers.contentType != ContentType.binary) {
      try {
        _receiveBuffer?.write(utf8.decode(data));
      } catch (ex) {
        if (kDebugMode) {
          print('Error decoding data: $ex');
        }
      }
    }
  }

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> event) convert) =>
      _wrapperStream!.asyncExpand(convert);

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> event) convert) =>
      _wrapperStream!.asyncMap(convert);

  @override
  Stream<E> cast<E>() => _wrapperStream!.cast<E>();

  @override
  Future<bool> contains(Object? needle) => _wrapperStream!.contains(needle);

  @override
  Future<bool> any(bool Function(List<int> element) test) =>
      _wrapperStream!.any(test);

  @override
  Stream<S> map<S>(S Function(List<int> event) convert) =>
      _wrapperStream!.map(convert);

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      _wrapperStream!.transform(streamTransformer);

  @override
  Future<E> drain<E>([E? futureValue]) => _wrapperStream!.drain(futureValue);

  @override
  Future<List<int>> elementAt(int index) => _wrapperStream!.elementAt(index);

  @override
  Future<bool> every(bool Function(List<int> element) test) =>
      _wrapperStream!.every(test);

  @override
  Stream<S> expand<S>(Iterable<S> Function(List<int> element) convert) =>
      _wrapperStream!.expand(convert);

  @override
  Future<List<int>> get first => _wrapperStream!.first;

  @override
  Future<List<int>> firstWhere(bool Function(List<int> element) test,
      {List<int> Function()? orElse}) =>
      _wrapperStream!.firstWhere(test, orElse: orElse);

  @override
  bool get isBroadcast => _wrapperStream!.isBroadcast;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _wrapperStream!.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  Future<void> pipe(StreamConsumer<List<int>> streamConsumer) =>
      _wrapperStream!.pipe(streamConsumer);

  @override
  Future<List<int>> reduce(
      List<int> Function(List<int> previous, List<int> element) combine) =>
      _wrapperStream!.reduce(combine);

  @override
  Future<List<int>> get single => _wrapperStream!.single;

  @override
  Future<List<int>> singleWhere(bool Function(List<int> element) test,
      {List<int> Function()? orElse}) =>
      _wrapperStream!.singleWhere(test, orElse: orElse);

  @override
  Stream<List<int>> asBroadcastStream(
      {void Function(StreamSubscription<List<int>>)? onListen,
        void Function(StreamSubscription<List<int>>)? onCancel}) =>
      _wrapperStream!.asBroadcastStream(onListen: onListen, onCancel: onCancel);

  @override
  Stream<List<int>> distinct(
      [bool Function(List<int> previous, List<int> next)? equals]) =>
      _wrapperStream!.distinct(equals);

  @override
  Future<E> fold<E>(
      E initialValue, E Function(E previous, List<int> element) combine) =>
      _wrapperStream!.fold(initialValue, combine);

  @override
  Future<void> forEach(void Function(List<int> element) action) =>
      _wrapperStream!.forEach(action);

  @override
  Stream<List<int>> handleError(Function onError,
      {bool Function(dynamic)? test}) =>
      _wrapperStream!.handleError(onError, test: test);

  @override
  Future<bool> get isEmpty => _wrapperStream!.isEmpty;

  @override
  Future<String> join([String separator = ""]) =>
      _wrapperStream!.join(separator);

  @override
  Future<List<int>> get last => _wrapperStream!.last;

  @override
  Future<List<int>> lastWhere(bool Function(List<int> element) test,
      {List<int> Function()? orElse}) =>
      _wrapperStream!.lastWhere(test, orElse: orElse);

  @override
  Future<int> get length => _wrapperStream!.length;

  @override
  Stream<List<int>> skip(int count) => _wrapperStream!.skip(count);

  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) =>
      _wrapperStream!.skipWhile(test);

  @override
  Stream<List<int>> take(int count) => _wrapperStream!.take(count);

  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) =>
      _wrapperStream!.takeWhile(test);

  @override
  Stream<List<int>> timeout(Duration timeLimit,
      {void Function(EventSink<List<int>> sink)? onTimeout}) =>
      _wrapperStream!.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<List<int>>> toList() => _wrapperStream!.toList();

  @override
  Future<Set<List<int>>> toSet() => _wrapperStream!.toSet();

  @override
  Stream<List<int>> where(bool Function(List<int> event) test) =>
      _wrapperStream!.where(test);

  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<Socket> detachSocket() => _inner.detachSocket();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followLoops]) async {
    return _inner.redirect(method, url, followLoops).then((response) {
      return _wrapResponse(
        response,
        requestID,
        originalUrl,
        originalMethod,
        timestamp,
        requestbody,
        requestHeaders: requestHeaders,
      );
    });
  }

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  int get statusCode => _inner.statusCode;

  void _readResponseBody(NetworkLoggerHttpClientResponse response,
      String? requestbody, Map<String, String> requestHeaders, int? timestamp) {
    String? noBodyReason;
    String? body;
    var options = getLaunchOptions()!;
    if (response.contentLength > options.maxNetworkBodySize) {
      noBodyReason = 'size_too_large';
    } else if (response.headers.contentType == null) {
      noBodyReason = 'no_content_type';
    } else if (response.headers.contentType == ContentType.binary) {
      noBodyReason = 'unsupported_content_type';
    } else if (response._receiveBuffer == null) {
      noBodyReason = 'cant_read_data';
    }
    /*else if (response._receiveBuffer != null &&
  response._receiveBuffer!.length > options.maxNetworkBodySize) {
  noBodyReason = 'size_too_large';
  }*/
    if (noBodyReason == null) {
      try {
        body = response._receiveBuffer?.toString();
      } catch (ex) {
        noBodyReason = 'cant_read_data';
      }
    }
    _registerCompleteEvent(
        response, noBodyReason, body, requestbody, requestHeaders, timestamp);
  }
}

class BmrtHttpClient implements HttpClient {
  final HttpClient _httpClient;

  BmrtHttpClient([HttpClient? httpClient, SecurityContext? context])
      : _httpClient = httpClient ?? HttpClient(context: context);

  @override
  bool get autoUncompress => _httpClient.autoUncompress;

  set autoUncompress(bool value) {
    _httpClient.autoUncompress = value;
  }

  @override
  Duration? get connectionTimeout => _httpClient.connectionTimeout;

  set connectionTimeout(Duration? value) {
    _httpClient.connectionTimeout = value;
  }

  @override
  Duration get idleTimeout => _httpClient.idleTimeout;

  set idleTimeout(Duration value) {
    _httpClient.idleTimeout = value;
  }

  @override
  int? get maxConnectionsPerHost => _httpClient.maxConnectionsPerHost;

  set maxConnectionsPerHost(int? value) {
    _httpClient.maxConnectionsPerHost = value;
  }

  @override
  String? get userAgent => _httpClient.userAgent;

  set userAgent(String? value) {
    _httpClient.userAgent = value;
  }

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    _httpClient.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {
    _httpClient.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f) {
    _httpClient.authenticate = f;
  }

  @override
  set authenticateProxy(
      Future<bool> Function(
          String host, int port, String scheme, String? realm)?
      f) {
    _httpClient.authenticateProxy = f;
  }

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {
    _httpClient.badCertificateCallback = callback;
  }

  @override
  void close({bool force = false}) {
    _httpClient.close(force: force);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return _wrapRequest(_httpClient.delete(host, port, path));
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return _wrapRequest(_httpClient.deleteUrl(url));
  }

  @override
  set findProxy(String Function(Uri url)? f) {
    _httpClient.findProxy = f;
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return _wrapRequest(_httpClient.get(host, port, path));
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return _wrapRequest(_httpClient.getUrl(url));
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return _wrapRequest(_httpClient.head(host, port, path));
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) async {
    return _wrapRequest(_httpClient.headUrl(url));
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    return _wrapRequest(_httpClient.open(method, host, port, path));
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return _wrapRequest(_httpClient.openUrl(method, url));
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return _wrapRequest(_httpClient.patch(host, port, path));
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return _wrapRequest(_httpClient.patchUrl(url));
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return _wrapRequest(_httpClient.post(host, port, path));
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _wrapRequest(_httpClient.postUrl(url));
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return _wrapRequest(_httpClient.put(host, port, path));
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return _wrapRequest(_httpClient.putUrl(url));
  }

  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
          Uri url, String? proxyHost, int? proxyPort)?
      f) {
    _httpClient.connectionFactory = f;
  }

  @override
  set keyLog(Function(String line)? callback) {
    _httpClient.keyLog = callback;
  }
}

class NetworkLoggerHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final int timestamp;
  final String requestID;
  StringBuffer? _sendBuffer = StringBuffer();

  NetworkLoggerHttpClientRequest(this._inner, [int? eventTimestamp])
      : requestID = _globalUuid.v4(),
        timestamp = eventTimestamp ?? DateTime.now().millisecondsSinceEpoch {
    // subscribe for the completion event right away so we will be notified
  }

  @override
  Uri get uri => _inner.uri;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  String get method => _inner.method;

  @override
  int get contentLength => _inner.contentLength;

  @override
  set contentLength(int _contentLength) =>
      _inner.contentLength = _contentLength;

  @override
  bool get followRedirects => _inner.followRedirects;

  @override
  set followRedirects(bool followRedirects) =>
      _inner.followRedirects = followRedirects;

  @override
  int get maxRedirects => _inner.maxRedirects;

  @override
  set maxRedirects(int maxRedirects) => _inner.maxRedirects = maxRedirects;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  set persistentConnection(bool persistentConnection) =>
      _inner.persistentConnection = persistentConnection;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);

  @override
  void add(List<int> data) {
    _addItems(data);
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    var newStream = _readAndRecreateStream(stream);
    return _inner.addStream(newStream);
  }

  @override
  Future<void> flush() => _inner.flush();

  @override
  void write(Object? object) {
    _inner.write(object);
    if (headers.contentType != ContentType.binary) {
      try {
        _sendBuffer?.write(object);
      } catch (ex) {
        // log error if required
      }
      _checkAndResetBufferIfRequired();
    }
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = ""]) {
    _inner.writeAll(objects);
    if (headers.contentType != ContentType.binary) {
      try {
        _sendBuffer?.writeAll(objects, separator);
      } catch (ex) {
        // log error if required
      }
      _checkAndResetBufferIfRequired();
    }
  }

  @override
  void writeCharCode(int charCode) {
    _inner.writeCharCode(charCode);
    if (headers.contentType != ContentType.binary) {
      try {
        _sendBuffer?.writeCharCode(charCode);
      } catch (ex) {
        // log error if required
      }
      _checkAndResetBufferIfRequired();
    }
  }

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding value) => _inner.encoding = value;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  Future<HttpClientResponse> get done => _inner.done;

  /* @override
  Future<HttpClientResponse> get done {
    var requestbody = _sendBuffer.toString();
    print("RequestBBB $requestbody");
    return _inner.done.then((response) => _wrapResponse(
        response,
        requestID,
        _inner.uri.toString(),
        _inner.method,
        timestamp,requestbody));
  }*/

  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  void writeln([Object? object = ""]) {
    _inner.writeln(object);
    if (headers.contentType != ContentType.binary) {
      try {
        _sendBuffer?.writeln(object);
      } catch (ex) {
        // log error if required
      }
      _checkAndResetBufferIfRequired();
    }
  }

  void _addItems(List<int> data) {
    if (headers.contentType != ContentType.binary) {
      try {
        _sendBuffer?.write(utf8.decode(data));
      } catch (ex) {
        if (kDebugMode) {
          print('Error decoding data: $ex');
        }
      }

      _checkAndResetBufferIfRequired();
    }
  }

  void _checkAndResetBufferIfRequired() {
    if (_sendBuffer != null &&
        _sendBuffer!.length > getLaunchOptions()!.maxNetworkBodySize) {
      // we have collected too many bytes -> reset buffer
      _sendBuffer = null;
    }
  }

  Stream<List<int>> _readAndRecreateStream(Stream<List<int>> source) async* {
    await for (var chunk in source) {
      _addItems(chunk);
      yield chunk;
    }
  }

  @override
  Future<HttpClientResponse> close() {
    return _inner.close().then((response) {
      var requestbody = _sendBuffer.toString();
      // Capture request headers as a map
      var requestHeaders = <String, String>{};
      _inner.headers.forEach((name, values) {
        requestHeaders[name] = values.join(', ');
      });
      var wrappedResponse = _wrapResponse(
        response,
        requestID,
        _inner.uri.toString(),
        _inner.method,
        timestamp,
        requestbody,
        requestHeaders: requestHeaders,
      );
      return wrappedResponse;
    }, onError: (dynamic err) {
      if (kDebugMode) {
        print(err);
      }
      // _registerErrorEvent()
    });
  }
}

class NetworkLoggerHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return BmrtHttpClient(super.createHttpClient(context));
  }
}
