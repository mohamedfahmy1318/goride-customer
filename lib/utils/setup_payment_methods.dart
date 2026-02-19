/// ============================================================================
/// GO RIDE CUSTOMER - Payment Methods Setup Script
/// ============================================================================
/// Run this script ONCE to initialize payment methods in Firestore.
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer';

class PaymentMethodsSetup {
  static FirebaseFirestore get _firestore {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app('goRide'),
      databaseId: 'default',
    );
  }

  /// Initialize or update payment methods in Firestore
  static Future<bool> setupMauritanianPaymentMethods() async {
    try {
      log('PaymentMethodsSetup: Starting setup...');

      final paymentRef = _firestore.collection('settings').doc('payment');

      final docSnapshot = await paymentRef.get();

      Map<String, dynamic> currentData = {};
      if (docSnapshot.exists) {
        currentData = docSnapshot.data() ?? {};
      }

      // Mauritanian payment methods
      final mauritanianPayments = {
        'bankily': {
          'name': 'Bankily',
          'enable': true,
          'isSandbox': false,
          'merchantId': '1006567',
          'description': 'الدفع عبر بنكيلي',
          'icon': 'bankily',
          'color': '#00A651',
          'sortOrder': 1,
        },
        'sedad': {
          'name': 'Sedad',
          'enable': true,
          'isSandbox': false,
          'merchantId': '', // TODO: Add merchant ID
          'description': 'الدفع عبر سداد',
          'icon': 'sedad',
          'color': '#2196F3',
          'sortOrder': 2,
        },
        'click': {
          'name': 'Click',
          'enable': true,
          'isSandbox': false,
          'merchantId': '', // TODO: Add merchant ID
          'description': 'الدفع عبر كليك / مصرفي',
          'icon': 'click',
          'color': '#FF9800',
          'sortOrder': 3,
        },
      };

      final updatedData = {
        ...currentData,
        ...mauritanianPayments,
      };

      await paymentRef.set(updatedData, SetOptions(merge: true));

      log('PaymentMethodsSetup: ✓ Payment methods configured successfully');
      return true;
    } catch (e) {
      log('PaymentMethodsSetup: ✗ Error: $e');
      return false;
    }
  }

  /// Create bankilyTransactions collection
  static Future<bool> setupBankilyTransactionsCollection() async {
    try {
      log('PaymentMethodsSetup: Creating bankilyTransactions collection...');

      final collectionRef = _firestore.collection('bankilyTransactions');

      await collectionRef.doc('_schema').set({
        '_description': 'Collection schema definition. DO NOT DELETE.',
        '_createdAt': FieldValue.serverTimestamp(),
        'sampleFields': {
          'id': 'string - Unique document ID',
          'transactionId': 'string - Unique transaction identifier',
          'oderId': 'string - Customer user ID',
          'amount': 'number - Transaction amount in MRU',
          'type': 'string - ridePayment, walletTopUp, intercityRide',
          'status': 'string - pending, processing, success, failed, cancelled',
          'provider': 'string - bankily, sedad, click',
          'orderId': 'string - Related order ID (nullable)',
          'createdAt': 'timestamp',
          'completedAt': 'timestamp (nullable)',
        },
      });

      log('PaymentMethodsSetup: ✓ bankilyTransactions collection created');
      return true;
    } catch (e) {
      log('PaymentMethodsSetup: ✗ Error: $e');
      return false;
    }
  }

  /// Run all setup tasks
  static Future<void> runFullSetup() async {
    log('========================================');
    log('GO RIDE CUSTOMER - Payment Setup');
    log('========================================');

    final paymentResult = await setupMauritanianPaymentMethods();
    final collectionResult = await setupBankilyTransactionsCollection();

    log('========================================');
    log('Setup Results:');
    log('  Payment Methods: ${paymentResult ? "✓ Success" : "✗ Failed"}');
    log('  Transactions Collection: ${collectionResult ? "✓ Success" : "✗ Failed"}');
    log('========================================');
  }
}
