import 'package:flutter/material.dart';

class CustomNavigatorObserver extends NavigatorObserver {
  List<Route<dynamic>> routeStack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    routeStack.add(route);
    print('Route pushed: ${route.settings.name}');
    _printStack();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    routeStack.remove(route);
    print('Route popped: ${route.settings.name}');
    _printStack();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    routeStack.remove(route);
    print('Route removed: ${route.settings.name}');
    _printStack();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      routeStack.remove(oldRoute);
    }
    if (newRoute != null) {
      routeStack.add(newRoute);
    }
    print(
        'Route replaced: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    _printStack();
  }

  void _printStack() {
    print('Current stack:');
    routeStack.forEach((route) {
      print(route.settings.name);
    });
  }
}
