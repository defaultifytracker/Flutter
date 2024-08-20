import 'package:flutter/material.dart';

class CustomRouteObserver extends NavigatorObserver {
  final List<ScreenInfo> screenList = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _addScreenInfo(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _addScreenInfo(previousRoute);
    }
  }

  void _addScreenInfo(Route<dynamic> route) {
    String screenClassName = _getScreenClassName(route);
    screenList.add(ScreenInfo(
        screenClassName, DateTime.now().millisecondsSinceEpoch.toString()));
  }

  String _getScreenClassName(Route<dynamic> route) {
    if (route.settings.name != null) {
      return route.settings.name!;
    }
    if (route is MaterialPageRoute) {
      return route.builder.toString().split(' => ').last.split('(').first;
    }
    return route.runtimeType.toString();
  }
}

class ScreenInfo {
  final String screenName;
  final String startTime; // Changed to String to match the timestamp format

  ScreenInfo(this.screenName, this.startTime);

  @override
  String toString() {
    return 'Screen: $screenName, Start Time: $startTime';
  }
}
