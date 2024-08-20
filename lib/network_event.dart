import 'cast_common.dart';
import 'network_modal.dart';

class NetworkEventImpl extends NetworkEvent {
  String _internalMethod = '';
  String _internalEventType = "";

  @override
  String get method => _internalMethod;
  @override
  String get type => _internalEventType;

  static NetworkEvent? fromRawEvent(dynamic event) {
    if (event == null) {
      return null;
    }
    NetworkEventImpl wrappedEvent = NetworkEventImpl();
    wrappedEvent._internalMethod = tryCast(event['method'], '');
    wrappedEvent._internalEventType = tryCast(event['type'], '');
    wrappedEvent.url = tryCast(event['url'], '');
    wrappedEvent.body = tryCast(event['body'], null);
    wrappedEvent.redirectUrl = tryCast(event['redirectUrl'], null);
    wrappedEvent.headers = tryCast(event['headers'], null);
    wrappedEvent.requestPayload == tryCast(event['requestPayload'], null);
    wrappedEvent.responseHeaders = tryCast(event['responseHeaders'], null);
    return wrappedEvent;
  }

  /// Convert class instance denoting the network event into
  /// the raw event data to pass it back to the native layer
  static dynamic augmentAndExtendOriginalEvent(
      dynamic originalEvent, NetworkEvent? e) {
    if (e == null) {
      return null;
    }

    originalEvent['url'] = e.url;
    originalEvent['body'] = e.body;
    originalEvent['redirectUrl'] = e.redirectUrl;
    originalEvent['headers'] = e.headers;

    return originalEvent;
  }
}
