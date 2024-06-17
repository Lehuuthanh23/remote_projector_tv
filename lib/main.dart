import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_box/view/authentication/login.page.dart';

import 'app/di.dart';
import 'view/splash/splash.page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjection.init();
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  static const platform = MethodChannel('com.example.app/channel');

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'performAction':
        print("MethodChannel called with performAction");
        break;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  @override
  Widget build(BuildContext context) {
    MyApp.platform.setMethodCallHandler(_handleMethod);
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
