import 'package:device_policy_controller/device_policy_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:play_box/app/app_sp.dart';
import 'package:play_box/app/app_sp_key.dart';
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
  initKioskMode();
  await DependencyInjection.init();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupLocator();
  runApp(const MyApp());
}

const bootCompletedHandlerStartedKey = "bootCompletedHandlerStarted";
final dpc = DevicePolicyController.instance;

Future<void> initKioskMode() async {
  dpc.handleBootCompleted((_) async {
    final startedValue = await dpc.get(bootCompletedHandlerStartedKey);
    print('startedValue: ${startedValue}');
    final isStarted = startedValue == "true";
    print('dpc:: handleBootCompleted:: isStarted: $isStarted');
    await dpc.put(bootCompletedHandlerStartedKey, content: "true");
    if (!isStarted) {
      try {
        await dpc.startApp();
        await enableKioskMode();
      } catch (e) {
        print('dpc:: handleBootCompleted startApp error: $e');
      }
    }
  });

  final startedValue = await dpc.get(bootCompletedHandlerStartedKey);
  final isStarted = startedValue == "true";
  print('dpc:: init:: startedValue $startedValue, isStarted: $isStarted');
  enableKioskMode();
}

Future<void> enableKioskMode() async {
  try {
    await dpc.lockApp(home: true);
    // await dpc.lockDevice(password: "1111");
    await dpc.setAsLauncher(enable: true);
    await dpc.setKeyguardDisabled(disabled: true);
    // await dpc.addUserRestrictions([
    //   "DISALLOW_INSTALL_APPS", // Ngăn cài đặt ứng dụng
    //   "DISALLOW_INSTALL_UNKNOWN_SOURCES", // Ngăn cài từ nguồn không xác định
    //   "DISALLOW_UNINSTALL_APPS", // Ngăn gỡ ứng dụng
    //   "DISALLOW_CONFIG_WIFI", // Ngăn thay đổi Wi-Fi
    //   "DISALLOW_CONFIG_BLUETOOTH", // Ngăn thay đổi Bluetooth
    //   "DISALLOW_FACTORY_RESET" // Ngăn reset thiết bị
    // ]);
    await dpc.setKeepScreenAwake(true);
    await dpc.put(bootCompletedHandlerStartedKey, content: "false"); //false
  } catch (e) {
    print('dpc:: enableKioskMode error: $e');
  }
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
    WidgetsBinding.instance.addObserver(this);
    _setupFirebaseMessaging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Hủy đăng ký
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('Vào didChangeAppLifecycleState');
    // Xử lý trạng thái vòng đời ứng dụng
    bool isSettingsOpened = AppSP.get(AppSPKey.isSettingsOpened);
    print(isSettingsOpened);
    if (state == AppLifecycleState.resumed && isSettingsOpened) {
      isSettingsOpened = false;
      AppSP.set(AppSPKey.isSettingsOpened, false);
      print('Lock app tiếp');
      dpc.lockApp(home: true);
    }
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
      title: 'TS Screen TV',
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
