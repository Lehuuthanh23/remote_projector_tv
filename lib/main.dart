import 'package:flutter/material.dart';
import 'package:play_box/view_models/home.vm.dart';
import 'observer/navigator_observer.dart';
import 'view/splash/splash.page.dart';
import 'app/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjection.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final HomeViewModel homeViewModel = HomeViewModel();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final CustomNavigatorObserver _navigatorObserver = CustomNavigatorObserver();

  @override
  Widget build(BuildContext context) {
    MyApp.homeViewModel.setMethodCall(null);
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorObservers: [_navigatorObserver],
      home: const SplashPage(),
    );
  }
}
