/// ============================================================================
/// GO RIDE - Bankily B-PAY Payment Configuration
/// ============================================================================
/// Direct integration with eBankily B-PAY API via Firebase Cloud Functions.
/// Merchant: GO RIDE SUARL - Code: 025647
/// ============================================================================

class BankilyConfig {
  // ============================================================================
  // MERCHANT INFORMATION
  // ============================================================================

  /// Merchant code (CIM) - GO RIDE SUARL
  static const String merchantCode = '025647';

  /// Merchant name
  static const String merchantName = 'GO RIDE SUARL';

  // ============================================================================
  // ENVIRONMENT
  // ============================================================================

  /// Set to true for production, false for testing
  static const bool isProduction = false;

  // ============================================================================
  // CURRENCY
  // ============================================================================

  /// Default currency for Mauritania
  static const String currency = 'MRU';

  /// Currency symbol
  static const String currencySymbol = 'MRU';

  // ============================================================================
  // TRANSACTION SETTINGS
  // ============================================================================

  /// Minimum transaction amount (in MRU)
  static const double minAmount = 1.0;

  /// Maximum transaction amount (in MRU)
  static const double maxAmount = 1000000.0;

  /// Transaction timeout in seconds (for polling status)
  static const int transactionTimeout = 120;

  /// Polling interval in seconds
  static const int pollingInterval = 3;

  // ============================================================================
  // BRANDING
  // ============================================================================

  /// Bankily brand color (green)
  static const int brandColor = 0xFF00A651;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Validate amount is within acceptable range
  static bool isValidAmount(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }
}
