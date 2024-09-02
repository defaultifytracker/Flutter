
# Defaultify for flutter

<hr />

**Defaultify Pluggin is now published as a [pub.dev](https://pub.dev) package. Refer to https://pub.dev/packages/defaultify to find out more.**

<hr />

Defaultify Plugin is a mobile SDK that adds crucial information to your bug and crash reports. Defaultify reports include video of user actions, network traffic, console logs and many other important traces from your app. Now you know what exactly led to the unexpected behavior.



## Installation

Install Defaultify plugin into your dart project by adding it to dependencies in your pubspec.yaml

```yaml
dependencies:
  defaultify: ^1.0.0
```

## Launching

```dart
import 'package:defaultify_plugin/defaultify_plugin.dart';

Future<void> launchDefaultify(
    void Function(bool isDftfyLaunched) appRunner) async {
  var token = "";
  if (Platform.isAndroid) {
    token = "";
  } else if (Platform.isIOS) {
    token = "";
  }
  await Defaultify.launch(token);
  appRunner(true);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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



