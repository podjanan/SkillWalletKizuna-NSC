import 'package:flutter/material.dart';

/// Global RouteObserver — add to MaterialApp.navigatorObservers
/// and subscribe in any screen that needs to react to route changes.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
