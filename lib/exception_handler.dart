import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:stack_trace/stack_trace.dart';

import 'launch_option.dart';
import 'version.dart';

class ExceptionHandler {
  final MethodChannel _channel;
  bool _isInstalled = false;
  bool _isActive = false;

  bool get isUnhandledInterceptionActive => _isActive;

  ExceptionHandler(MethodChannel channel) : _channel = channel;

  Future<void> logException(dynamic exception, bool handled,
      [dynamic stackTrace]) async {
    final Chain chain = _getStackTraceChain(stackTrace);

    final List<Map<String, dynamic>> frames = <Map<String, dynamic>>[];

    var ds = AccumulatorSink<Digest>();
    var s = sha1.startChunkedConversion(ds);

    s.add(utf8.encode(getApplicationVersionInternal()));

    for (var trace in chain.traces) {
      for (var frame in trace.frames) {
        frames.add(_constructFrame(frame));
        s.add(utf8.encode(frame.location));
      }
    }

    s.close();

    // Assuming you want to send the location of the first frame
    final Frame? firstFrame =
        chain.traces.expand((trace) => trace.frames).firstOrNull;

    final String location = firstFrame != null
        ? '${firstFrame.member} (${firstFrame.uri.toString().split('/').last}:${firstFrame.line})'
        : 'unknown';

    await _channel.invokeMethod('logException', <String, dynamic>{
      'name': exception.runtimeType.toString(),
      'reason': exception.toString(),
      'stackTrace': frames.map((frame) => json.encode(frame)).toList(),
      'handled': handled,
      'signature': ds.events.single.toString(),
      'location': location,
    });
  }

  Map<String, dynamic> _constructFrame(Frame frame) {
    Uri frameUri = frame.uri;
    String? package = frame.package;
    bool user = true;
    String stringUri = frameUri.toString();

    if (frameUri.scheme != 'dart' && frameUri.scheme != 'package') {
      if (frameUri.pathSegments.isNotEmpty) {
        stringUri = frameUri.pathSegments.last;
      }
    }

    if (frameUri.scheme == 'hooks' ||
        frameUri.scheme == 'dart' ||
        package == 'flutter') {
      user = false;
    }

    package ??= (frameUri.scheme == 'dart') ? 'dart' : 'application';

    return <String, dynamic>{
      'trace': '${frame.member} ($stringUri:${frame.line})',
      'module': package,
      'user': user,
      'data': {
        'uri': frame.uri.toString(),
        'member': frame.member,
        'line': frame.line,
        'column': frame.column,
        'package': frame.package,
        'library': frame.library,
        'isCore': frame.isCore
      }
    };
  }

  /// Get the stack chain for the specified stack trace or
  /// retrive current stack chain if no stack trace provided
  Chain _getStackTraceChain([dynamic stackTrace]) {
    Chain chain;

    if (stackTrace == null || stackTrace == '') {
      // we instruct the runtime to give us the stack chain with two
      // first frames skipped. This is required to exclude the calls
      // to this method and the one calling it (as this method is
      // marked as internal, it will be called from one of the
      // instance methods of this class)
      chain = Chain.current(2);
    } else {
      stackTrace = FlutterError.demangleStackTrace(stackTrace);
      chain = Chain.forTrace(stackTrace);
    }

    return chain;
  }

  void installGlobalErrorHandler([bool force = false]) {
    if (_isInstalled && !force) {
      return;
    }

    final defaultOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails errorDetails) async {
      Object exception = errorDetails.exception;
      StackTrace? stack = errorDetails.stack;

      if (_isActive) {
        await logException(exception, false, stack);
      }

      // call original handler
      if (defaultOnError != null) {
        defaultOnError(errorDetails);
      }
    };

    _isInstalled = true;
  }

  void activateUnhandledInterception() {
    _isActive = true;
  }

  void deactivateUnhandledInterception() {
    _isActive = false;
  }

  void syncWithOptions(LaunchOptions? launchOptions) {
    if (launchOptions != null) {
      _isActive = launchOptions.crashReport;
    }
  }
}
