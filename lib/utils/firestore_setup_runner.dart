/// ============================================================================
/// GO RIDE CUSTOMER - One-Time Firestore Setup Runner
/// ============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/utils/Preferences.dart';
import 'dart:developer';

class FirestoreSetupRunner {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _setupVersion = '1.0.0';

  /// Run this ONCE to setup all payment configurations
  static Future<void> runOnce() async {
    if (Preferences.getString(Preferences.firestoreSetupVersionKey) ==
        _setupVersion) {
      return;
    }
    log('🚀 FirestoreSetupRunner: Starting one-time setup...');

    try {
      final setupDoc =
          await _firestore.collection('settings').doc('_setup_completed').get();

      if (setupDoc.exists) {
        await Preferences.setString(
            Preferences.firestoreSetupVersionKey, _setupVersion);
        log('⚠️ Setup already completed. Skipping...');
        return;
      }

      await _setupPaymentMethods();
      await _setupTransactionsCollections();

      await _firestore.collection('settings').doc('_setup_completed').set({
        'mauritanianPayments': true,
        'completedAt': FieldValue.serverTimestamp(),
        'version': _setupVersion,
      });

      await Preferences.setString(
          Preferences.firestoreSetupVersionKey, _setupVersion);

      log('✅ FirestoreSetupRunner: All setup completed successfully!');
    } catch (e) {
      log('❌ FirestoreSetupRunner: Setup failed: $e');
    }
  }

  static Future<void> _setupPaymentMethods() async {
    log('📦 Setting up payment methods...');

    final paymentRef = _firestore.collection('settings').doc('payment');

    await paymentRef.set({
      'bankily': {
        'name': 'Bankily',
        'enable': true,
        'isSandbox': false,
        'merchantId': '1006567',
        'description': 'الدفع عبر بنكيلي',
        'icon': 'bankily',
        'color': '#00A651',
        'sortOrder': 100,
      },
      'sedad': {
        'name': 'Sedad',
        'enable': true,
        'isSandbox': false,
        'merchantId': '',
        'description': 'الدفع عبر سداد',
        'icon': 'sedad',
        'color': '#2196F3',
        'sortOrder': 101,
      },
      'click': {
        'name': 'Click',
        'enable': true,
        'isSandbox': false,
        'merchantId': '',
        'description': 'الدفع عبر كليك / مصرفي',
        'icon': 'click',
        'color': '#FF9800',
        'sortOrder': 102,
      },
    }, SetOptions(merge: true));

    log('✓ Payment methods configured');
  }

  static Future<void> _setupTransactionsCollections() async {
    log('📦 Setting up transaction collections...');

    await _firestore.collection('bankilyTransactions').doc('_schema').set({
      '_info': 'Schema definition for Customer app payments',
      '_createdAt': FieldValue.serverTimestamp(),
      'fields': {
        'id': 'string',
        'transactionId': 'string',
        'oderId': 'string (customer user ID)',
        'orderId': 'string (order ID, optional)',
        'amount': 'double',
        'type': 'enum: ridePayment, walletTopUp, intercityRide',
        'status': 'enum: pending, processing, success, failed, cancelled',
        'provider': 'enum: bankily, sedad, click',
        'createdAt': 'DateTime',
        'completedAt': 'DateTime (optional)',
      },
    });

    await _firestore.collection('moosyl_transactions').doc('_schema').set({
      '_info': 'Schema definition for Driver app payments',
      '_createdAt': FieldValue.serverTimestamp(),
      'fields': {
        'id': 'string',
        'transactionId': 'string',
        'oderId': 'string (driver user ID)',
        'amount': 'double',
        'type': 'enum: walletTopUp, subscription, withdrawal',
        'status': 'enum: pending, processing, success, failed, cancelled',
        'provider': 'enum: bankily, sedad, click, masrivi',
        'createdAt': 'DateTime',
        'completedAt': 'DateTime (optional)',
      },
    });

    log('✓ Transaction collections created');
  }

  static Future<void> forceRerun() async {
    await _firestore.collection('settings').doc('_setup_completed').delete();
    await Preferences.clearKeyData(Preferences.firestoreSetupVersionKey);
    await runOnce();
  }
}
