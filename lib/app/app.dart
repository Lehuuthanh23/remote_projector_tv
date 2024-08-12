import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

import '../view/authentication/login.page.dart';
import '../view/home/home.page.dart';
import '../view/splash/splash.page.dart';
import '../view/video_camp/view_camp.dart';

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
