import 'dart:io';
import 'package:defaultify_plugin/defaultify_plugin.dart';
import 'package:flutter/material.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await launchDefaultify((bool isDftfyLaunched) async {
    runApp(const MyApp());
  });
}

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Dftfy LAUNCH',
            ),
            SizedBox(
              height: 100,
            ),
            Text('Running on1:'),
            SizedBox(
              height: 100,
            ),
            Text('Running on1:'),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}