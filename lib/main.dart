import 'package:flutter/material.dart';
import 'app/di.dart';
import 'view/splash/splash.page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjection.init();
  // final app = shelf_router.Router();

  // app.get('/current_time', (Request request) {
  //   final now = DateTime.now();
  //   final formattedTime = now.toIso8601String();
  //   return Response.ok(formattedTime);
  // });

  // final server = await shelf_io.serve(app, '0.0.0.0', 8080);
  // print('Server running on localhost:${server.port}');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashPage());
  }
}
