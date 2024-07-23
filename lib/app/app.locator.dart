// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

final appLocator = StackedLocator.instance;

Future<void> setupLocator({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async {
// Register environments
  appLocator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies
  appLocator.registerLazySingleton(() => NavigationService());
  appLocator
      .registerLazySingleton(() => NavigationService(), registerFor: {"dev"});
}
