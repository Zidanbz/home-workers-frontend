import 'package:flutter/material.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String? _pendingOrderId;
  static bool _authenticatedRouteReady = false;

  static void setAuthenticatedRouteReady(bool ready) {
    _authenticatedRouteReady = ready;
    if (ready) flushPending();
  }

  static void openOrder(String orderId) {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (!_authenticatedRouteReady || navigator == null) {
      _pendingOrderId = normalizedOrderId;
      return;
    }

    navigator.pushNamed('/order-detail', arguments: normalizedOrderId);
  }

  static void flushPending() {
    if (!_authenticatedRouteReady) return;
    final pendingOrderId = _pendingOrderId;
    final navigator = navigatorKey.currentState;
    if (pendingOrderId == null || navigator == null) return;

    _pendingOrderId = null;
    navigator.pushNamed('/order-detail', arguments: pendingOrderId);
  }
}
