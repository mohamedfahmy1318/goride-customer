import 'dart:developer';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized Firebase Analytics service.
/// Tracks screens, events, and user properties across the app.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Log the current screen name
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      log('AnalyticsService.logScreenView error: $e');
    }
  }

  /// Set the current user ID for all subsequent events
  static Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      log('AnalyticsService.setUserId error: $e');
    }
  }

  /// Set a user property (e.g., region, subscription type)
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      log('AnalyticsService.setUserProperty error: $e');
    }
  }

  /// Log a custom event
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      log('AnalyticsService.logEvent error: $e');
    }
  }

  // ── App-specific events ──

  /// User logged in
  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// User signed up
  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  /// Ride requested
  static Future<void> logRideRequested({
    required String serviceType,
    required String paymentMethod,
  }) async {
    await logEvent(name: 'ride_requested', parameters: {
      'service_type': serviceType,
      'payment_method': paymentMethod,
    });
  }

  /// Ride completed
  static Future<void> logRideCompleted({
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    await logEvent(name: 'ride_completed', parameters: {
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
    });
  }

  /// Ride cancelled
  static Future<void> logRideCancelled({required String reason}) async {
    await logEvent(name: 'ride_cancelled', parameters: {'reason': reason});
  }

  /// Wallet top-up
  static Future<void> logWalletTopUp({
    required double amount,
    required String method,
  }) async {
    await logEvent(name: 'wallet_topup', parameters: {
      'amount': amount,
      'method': method,
    });
  }

  /// Payment completed
  static Future<void> logPaymentCompleted({
    required String orderId,
    required double amount,
    required String method,
  }) async {
    await _analytics.logPurchase(
      currency: 'MRU',
      value: amount,
      transactionId: orderId,
    );
  }
}
