import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navKey.currentState;

  static Future<T?> push<T>(Route<T> route) async {
    return navKey.currentState?.push(route);
  }
}
