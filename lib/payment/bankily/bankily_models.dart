/// ============================================================================
/// GO RIDE - Bankily B-PAY Payment Models
/// ============================================================================
/// Models for the eBankily B-PAY direct API integration.
/// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment type enum
enum BankilyPaymentType {
  ridePayment,
  walletTopUp,
  intercityRide,
}

/// Payment status
enum BankilyPaymentStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
}

/// Request model for Bankily B-PAY payment
class BankilyPaymentRequest {
  final String operationId;
  final String clientPhone;
  final String passcode;
  final double amount;
  final String language;
  final BankilyPaymentType paymentType;
  final String? orderId;

  BankilyPaymentRequest({
    required this.operationId,
    required this.clientPhone,
    required this.passcode,
    required this.amount,
    this.language = 'ar',
    required this.paymentType,
    this.orderId,
  });

  /// Generate a unique operation ID
  /// Format: GORIDE_[TYPE]_[TIMESTAMP]
  static String generateOperationId(BankilyPaymentType type) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = switch (type) {
      BankilyPaymentType.ridePayment => 'RIDE',
      BankilyPaymentType.walletTopUp => 'TOPUP',
      BankilyPaymentType.intercityRide => 'INTER',
    };
    return 'GR_${prefix}_$timestamp';
  }

  /// Convert to map for Cloud Function call
  Map<String, dynamic> toJson() {
    return {
      'clientPhone': clientPhone,
      'passcode': passcode,
      'amount': amount.toInt().toString(),
      'operationId': operationId,
      'language': language,
    };
  }
}

/// Response model from Bankily B-PAY payment
class BankilyPaymentResponse {
  final bool success;
  final String errorCode;
  final String errorMessage;
  final String? transactionId;

  BankilyPaymentResponse({
    required this.success,
    required this.errorCode,
    required this.errorMessage,
    this.transactionId,
  });

  factory BankilyPaymentResponse.fromJson(Map<String, dynamic> json) {
    return BankilyPaymentResponse(
      success: json['success'] == true,
      errorCode: json['errorCode']?.toString() ?? '',
      errorMessage: json['errorMessage']?.toString() ?? '',
      transactionId: json['transactionId']?.toString(),
    );
  }

  /// Error codes:
  /// 0 = success
  /// 1 = other error
  /// 2 = invalid token
  /// 4 = Operation ID required
  bool get isSuccess => errorCode == '0';
}

/// Response model from Bankily check transaction
class BankilyCheckResponse {
  final bool success;
  final String errorCode;
  final String errorMessage;
  final String? transactionId;
  final String status; // success, failed, pending

  BankilyCheckResponse({
    required this.success,
    required this.errorCode,
    required this.errorMessage,
    this.transactionId,
    required this.status,
  });

  factory BankilyCheckResponse.fromJson(Map<String, dynamic> json) {
    return BankilyCheckResponse(
      success: json['success'] == true,
      errorCode: json['errorCode']?.toString() ?? '',
      errorMessage: json['errorMessage']?.toString() ?? '',
      transactionId: json['transactionId']?.toString(),
      status: json['status']?.toString() ?? 'unknown',
    );
  }

  /// Transaction status:
  /// TS = transaction success
  /// TF = transaction failed
  /// TA = transaction pending
  bool get isSuccess => status == 'success';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}

/// Firestore transaction record
class BankilyTransaction {
  final String operationId;
  final String userId;
  final double amount;
  final String clientPhone;
  final BankilyPaymentType type;
  final BankilyPaymentStatus status;
  final String? orderId;
  final String? transactionId;
  final String? errorMessage;
  final Timestamp? createdAt;
  final Timestamp? completedAt;

  BankilyTransaction({
    required this.operationId,
    required this.userId,
    required this.amount,
    required this.clientPhone,
    required this.type,
    required this.status,
    this.orderId,
    this.transactionId,
    this.errorMessage,
    this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'userId': userId,
      'amount': amount,
      'clientPhone': clientPhone,
      'type': type.name,
      'status': status.name,
      'orderId': orderId,
      'transactionId': transactionId,
      'errorMessage': errorMessage,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'completedAt': completedAt,
    };
  }

  factory BankilyTransaction.fromJson(Map<String, dynamic> json) {
    return BankilyTransaction(
      operationId: json['operationId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      clientPhone: json['clientPhone'] ?? '',
      type: BankilyPaymentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BankilyPaymentType.ridePayment,
      ),
      status: BankilyPaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BankilyPaymentStatus.pending,
      ),
      orderId: json['orderId'],
      transactionId: json['transactionId'],
      errorMessage: json['errorMessage'],
      createdAt: json['createdAt'] as Timestamp?,
      completedAt: json['completedAt'] as Timestamp?,
    );
  }
}
