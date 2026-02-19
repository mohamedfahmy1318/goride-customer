/// ============================================================================
/// GO RIDE - Bankily B-PAY Payment Service
/// ============================================================================
/// Handles Bankily payments via Firebase Cloud Functions.
/// The Cloud Function communicates with the eBankily B-PAY API server-side.
/// ============================================================================

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/payment/bankily/bankily_models.dart';
import 'package:customer/utils/fire_store_utils.dart';

/// Service class for handling Bankily B-PAY payments
class BankilyService {
  static final BankilyService _instance = BankilyService._internal();
  factory BankilyService() => _instance;
  BankilyService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  FirebaseFirestore get _firestore => FireStoreUtils.fireStore;

  // ============================================================================
  // PAYMENT
  // ============================================================================

  /// Process a Bankily B-PAY payment via Cloud Function
  /// Returns [BankilyPaymentResponse] with the result
  Future<BankilyPaymentResponse> processPayment({
    required String clientPhone,
    required String passcode,
    required double amount,
    required String operationId,
    String language = 'ar',
  }) async {
    try {
      log('BankilyService: Processing payment - $operationId, amount: $amount');

      final callable = _functions.httpsCallable(
        'bankilyPayment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 70)),
      );

      final result = await callable.call({
        'clientPhone': clientPhone,
        'passcode': passcode,
        'amount': amount.toInt().toString(),
        'operationId': operationId,
        'language': language,
      });

      final response = BankilyPaymentResponse.fromJson(
        Map<String, dynamic>.from(result.data),
      );

      log('BankilyService: Payment result - success: ${response.success}, '
          'errorCode: ${response.errorCode}, msg: ${response.errorMessage}');

      return response;
    } on FirebaseFunctionsException catch (e) {
      log('BankilyService: Cloud Function error - ${e.code}: ${e.message}');
      return BankilyPaymentResponse(
        success: false,
        errorCode: e.code,
        errorMessage: e.message ?? 'فشل في عملية الدفع',
      );
    } catch (e) {
      log('BankilyService: Error - $e');
      return BankilyPaymentResponse(
        success: false,
        errorCode: '-1',
        errorMessage: 'حدث خطأ في الاتصال. حاول مرة أخرى.',
      );
    }
  }

  // ============================================================================
  // CHECK TRANSACTION
  // ============================================================================

  /// Check the status of a Bankily transaction via Cloud Function
  Future<BankilyCheckResponse> checkTransaction({
    required String operationId,
  }) async {
    try {
      log('BankilyService: Checking transaction - $operationId');

      final callable = _functions.httpsCallable(
        'bankilyCheckTransaction',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
      );

      final result = await callable.call({
        'operationId': operationId,
      });

      final response = BankilyCheckResponse.fromJson(
        Map<String, dynamic>.from(result.data),
      );

      log('BankilyService: Check result - status: ${response.status}');
      return response;
    } on FirebaseFunctionsException catch (e) {
      log('BankilyService: Check error - ${e.code}: ${e.message}');
      return BankilyCheckResponse(
        success: false,
        errorCode: e.code,
        errorMessage: e.message ?? 'فشل في التحقق',
        status: 'error',
      );
    } catch (e) {
      log('BankilyService: Check error - $e');
      return BankilyCheckResponse(
        success: false,
        errorCode: '-1',
        errorMessage: 'حدث خطأ في الاتصال',
        status: 'error',
      );
    }
  }

  // ============================================================================
  // WALLET TOP-UP
  // ============================================================================

  /// Process wallet top-up after successful Bankily payment
  Future<bool> processWalletTopUp({
    required double amount,
    required String operationId,
  }) async {
    try {
      final userId = FireStoreUtils.getCurrentUid();

      // Create wallet transaction record
      final walletTransaction = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: amount.toString(),
        createdDate: Timestamp.now(),
        paymentType: 'Bankily',
        transactionId: operationId,
        userId: userId,
        orderType: 'wallet',
        userType: 'customer',
        note: 'شحن المحفظة عبر Bankily',
      );

      // Save wallet transaction
      await FireStoreUtils.setWalletTransaction(walletTransaction);

      // Update user wallet balance
      await FireStoreUtils.updateUserWallet(amount: amount.toString());

      log('BankilyService: Wallet top-up processed - $amount MRU');
      return true;
    } catch (e) {
      log('BankilyService: Wallet top-up error - $e');
      return false;
    }
  }

  // ============================================================================
  // LOCAL TRANSACTION RECORD
  // ============================================================================

  /// Save a local transaction record
  Future<void> saveLocalTransaction({
    required String operationId,
    required double amount,
    required String clientPhone,
    required BankilyPaymentType type,
    required BankilyPaymentStatus status,
    String? orderId,
    String? transactionId,
    String? errorMessage,
  }) async {
    try {
      final userId = FireStoreUtils.getCurrentUid();

      final transaction = BankilyTransaction(
        operationId: operationId,
        userId: userId,
        amount: amount,
        clientPhone: clientPhone,
        type: type,
        status: status,
        orderId: orderId,
        transactionId: transactionId,
        errorMessage: errorMessage,
      );

      await _firestore
          .collection(CollectionName.bankilyTransactions)
          .doc(operationId)
          .set(transaction.toJson(), SetOptions(merge: true));
    } catch (e) {
      log('BankilyService: Save transaction error - $e');
    }
  }
}
