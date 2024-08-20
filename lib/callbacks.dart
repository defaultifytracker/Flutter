import 'package:flutter/foundation.dart';

import 'network_event.dart';
import 'network_modal.dart';

class Callbacks {
  NetworkFilterCallback? _networkFilterCallback;

  void setNetworkFilter(NetworkFilterCallback? callback) {
    _networkFilterCallback = callback;
  }

  Future<dynamic> networkFilterCallback(dynamic originalEvent) async {
    if (_networkFilterCallback != null) {
      try {
        var wrappedEvent = NetworkEventImpl.fromRawEvent(originalEvent);
        if (wrappedEvent != null) {
          wrappedEvent = await _networkFilterCallback!(wrappedEvent);
          var finalValue = NetworkEventImpl.augmentAndExtendOriginalEvent(
              originalEvent, wrappedEvent);
          if (finalValue != null) {
            return Future.value(finalValue);
          } else {
            return Future.value(null);
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("RawExp$e");
        }
      }
    }

    return Future.value(originalEvent);
  }
}
