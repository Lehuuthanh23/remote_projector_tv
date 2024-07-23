import 'package:play_box/view/authentication/login.page.dart';
import 'package:play_box/view/video_camp/view_camp.dart';
import 'package:play_box/view_models/home.vm.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import '../view/home/home.page.dart';
import '../view/splash/splash.page.dart';
import '../view_models/splash.vm.dart';

@StackedApp(
  routes: [
    MaterialRoute(page: SplashPage, initial: true),
    MaterialRoute(page: LoginPage),
    MaterialRoute(page: HomePage),
    MaterialRoute(page: ViewCamp),
  ],
  dependencies: [
    // Lazy singletons
    LazySingleton(classType: NavigationService),
    LazySingleton(
      classType: NavigationService,
      environments: {Environment.dev},
    ),
  ],
  logger: StackedLogger(),
  locatorName: 'appLocator',
  locatorSetupName: 'setupLocator',
)
class App {
  /// This class has no puporse besides housing the annotation that generates the required functionality
}
