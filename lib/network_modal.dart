abstract class NetworkEvent {
  String get type;
  String get method;
  String url = "";
  String? redirectUrl;
  String? body;
  Map<String, dynamic>? headers;
  String? requestPayload;
  Map<String, dynamic>? responseHeaders;
}

typedef NetworkFilterCallback = Future<NetworkEvent?> Function(NetworkEvent e);
