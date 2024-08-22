# bmrt_plugin

A new Flutter project.

# Plugin for flutter

<hr />

**Flutter Pluggin is now published as a [pub.dev](https://pub.dev) package. Refer to https://pub.dev/packages/test_defaultify_plugin to find out more.**

<hr />

Bmrt Plugin is a mobile SDK that adds crucial information to your bug and crash reports. Bmrt reports include video of user actions, network traffic, console logs and many other important traces from your app. Now you know what exactly led to the unexpected behavior.



## Installation

Install Bmrt plugin into your dart project by adding it to dependencies in your pubspec.yaml

```yaml
dependencies:
  Testbmrt_flutter:
    git:
      url: http://gitlab.appinvent.in/bmrt/flutter.git
      # ref: 1.2.3 # if forcing a specific version by tag or branch
```

## Launching

```dart
import 'package:Testbmrt_flutter/test_bmrt.dart';

Future<Null> launchBmrtTest(Function(bool isTestbmrtLaunched) appRunner) async {
  var launchOptions;
  var token = "";

  if (Platform.isAndroid) {
    token = "<android app token>";
    launchOptions = new AndroidLaunchOptions();
  } else if (Platform.isIOS) {
    token = "<ios app token>";
    launchOptions = new IOSLaunchOptions();
  }

  await launchBmrtTest.launch(token,
      appRunCallback: appRunner, launchOptions: launchOptions);
}

Future<Null> main() async {
  await launchBmrtTest((bool isLaunched) async {
    runApp(new MyApp());
  });
}

class MyApp extends StatelessWidget {
  ....
```



