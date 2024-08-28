# Defaultify_plugin

A new Flutter project.

# Plugin for flutter

<hr />

**Defaultify Pluggin is now published as a [pub.dev](https://pub.dev) package. Refer to https://pub.dev/packages/defaultify to find out more.**

<hr />

Defaultify Plugin is a mobile SDK that adds crucial information to your bug and crash reports. Defaultify reports include video of user actions, network traffic, console logs and many other important traces from your app. Now you know what exactly led to the unexpected behavior.



## Installation

Install Defaultify plugin into your dart project by adding it to dependencies in your pubspec.yaml

```yaml
dependencies:
  TestDefaultify_flutter:
    git:
      url: https://github.com/defaultifytracker/FlutterDevelopment.git
      # ref: 1.2.3 # if forcing a specific version by tag or branch
```

## Launching

```dart
import 'package:TestDefaultify_flutter/test_Defaultify.dart';

Future<Null> launchDefaultify(Function(bool isTestDefaultifyLaunched) appRunner) async {
  var launchOptions;
  var token = "";

  if (Platform.isAndroid) {
    token = "<android app token>";
  } else if (Platform.isIOS) {
    token = "<ios app token>";
  }

  await Defaultify.launch(token);
}

Future<Null> main() async {
  await launchDefaultify((bool isDftfyLaunched) async {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorObservers: [Defaultify.customRouteObserver],
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
  
}
....
```



