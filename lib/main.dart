import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stacked_services/stacked_services.dart';

import 'app/app.locator.dart';
import 'app/app.router.dart';
import 'app/app_string.dart';
import 'app/di.dart';
import 'observer/navigator_observer.dart';
import 'request/command/command.request.dart';
import 'view/splash/splash.page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjection.init();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupLocator();
  runApp(const MyApp());
}

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  String? commandId = message.data['cmd_id'];
  String? command = message.data['cmd_code'];

  if (command != null && commandId != null) {
    String? replyContent;

    if (command == AppString.getTimeNow) {
      DateTime now = DateTime.now().toUtc().add(const Duration(hours: 7));
      replyContent = DateFormat('HH:mm:ss').format(now);
    } else if (command == AppString.restartApp ||
        command == AppString.wakeUpApp) {
      replyContent = null;
    } else {
      replyContent = AppString.notPlayVideo;
    }

    if (replyContent != null) {
      CommandRequest().replyCommand(commandId, replyContent);
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final CustomNavigatorObserver _navigatorObserver = CustomNavigatorObserver();

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GT GLOBAL TV',
      debugShowCheckedModeBanner: false,
      navigatorKey: StackedService.navigatorKey,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      initialRoute: Routes.splashPage,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorObservers: [_navigatorObserver],
      home: const SplashPage(),
    );
  }
}
