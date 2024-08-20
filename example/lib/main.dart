import 'dart:io';
import 'package:defaultify_plugin/defaultify_plugin.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

// void main() {
//   runApp(const MyApp());
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await launchDefaultify((bool isDftfyLaunched) async {
  runApp(const MyApp());
  // });
}

Future<void> launchDefaultify(
    void Function(bool isDftfyLaunched) appRunner) async {
  var dftfyToken = "";
  if (Platform.isAndroid) {
    dftfyToken = "0c56d0ba-a589-4aae-9f7d-519fdf4f680b";
  } else if (Platform.isIOS) {
    dftfyToken = "da543660-858e-4eab-9147-6e0aace1a703";
  }
  await DefaultifyPlugin.launch(dftfyToken);
  appRunner(true);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final defaultify = DefaultifyPlugin();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await DefaultifyPlugin.launch("da543660-858e-4eab-9147-6e0aace1a703");
    return;
    // Hello.launch("da543660-858e-4eab-9147-6e0aace1a703");
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await defaultify.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
