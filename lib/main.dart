import 'dart:async';

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
import 'services/alarm_service.dart';
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
  bool isAdmin = await dpc.isAdminActive();
  if (isAdmin) {
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
  }

  final startedValue = await dpc.get(bootCompletedHandlerStartedKey);
  final isStarted = startedValue == "true";
  print('dpc:: init:: startedValue $startedValue, isStarted: $isStarted');
  enableKioskMode();
}

Future<void> enableKioskMode() async {
  try {
    bool isAdmin = await dpc.isAdminActive();
    await dpc.setAsLauncher(enable: false);
    if (isAdmin) {
      await dpc.lockApp(home: true);
      // await dpc.setAsLauncher(enable: true);
      await dpc.setKeyguardDisabled(disabled: true);
      await dpc.setKeepScreenAwake(true);
    }
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
    dpc.unlockApp();
    dpc.setAsLauncher(enable: false);
    // Xử lý trạng thái vòng đời ứng dụng
    bool isSettingsOpened = AppSP.get(AppSPKey.isSettingsOpened) ?? false;
    print(isSettingsOpened);
    if (state == AppLifecycleState.resumed && isSettingsOpened) {
      isSettingsOpened = false;
      AppSP.set(AppSPKey.isSettingsOpened, false);
      print('Lock app tiếp');
      if (AppSP.get(AppSPKey.isKioskMode) == true) {
        dpc.lockApp(home: true);
      } else {
        AppSP.set(AppSPKey.isKioskMode, false);
        dpc.unlockApp();
      }
      // dpc.setAsLauncher(enable: false);
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
      title: 'TS Screen',
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

class SleepDevicePage extends StatefulWidget {
  @override
  _SleepDevicePageState createState() => _SleepDevicePageState();
}

class _SleepDevicePageState extends State<SleepDevicePage> {
  Timer? _timer;
  final AlarmService _alarmService = AlarmService();

  void _scheduleSleep(Duration delay) async {
    bool isDeviceOwner = await DevicePolicyController.instance.isAdminActive();

    if (isDeviceOwner) {
      print('isDeviceOwner: $isDeviceOwner');
      print(delay.inMinutes);
      // _timer = Timer(delay, () async {
      bool success = await DevicePolicyController.instance.lockDevice();
      print('success: $success');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thiết bị đã được khóa.')),
        );
        print('Thiết bị đã được khóa.');
        await _alarmService.setWakeUpAlarm(delay.inSeconds);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể khóa thiết bị.')),
        );
        print('Không thể khóa thiết bị.');
      }
      // });

      // Đặt alarm để đánh thức thiết bị sau khoảng thời gian trì hoãn

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Đã đặt lịch khóa thiết bị sau ${delay.inMinutes} phút và đánh thức sau cùng.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ứng dụng không phải là Device Owner.')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Duration delay = const Duration(minutes: 1); // Thời gian trì hoãn

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt Lịch Ngủ Thiết Bị'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _scheduleSleep(delay);
          },
          child: const Text('Đặt Lịch Khóa Sau 5 Phút'),
        ),
      ),
    );
  }
}
