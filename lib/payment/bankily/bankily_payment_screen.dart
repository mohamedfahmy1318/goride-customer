/// ============================================================================
/// GO RIDE - Bankily B-PAY Payment Screen
/// ============================================================================
/// This screen handles the Bankily B-PAY payment flow:
/// 1. User opens Bankily app, goes to B-PAY
/// 2. Enters merchant code (025647) and amount
/// 3. Confirms payment, gets a passcode
/// 4. Enters phone number + passcode here
/// 5. We call Cloud Function -> eBankily API to process payment
/// ============================================================================

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/payment/bankily/bankily_config.dart';
import 'package:customer/payment/bankily/bankily_models.dart';
import 'package:customer/payment/bankily/bankily_service.dart';

/// Bankily B-PAY Payment Screen
class BankilyPaymentScreen extends StatefulWidget {
  final double amount;
  final BankilyPaymentType paymentType;
  final String? orderId;
  final VoidCallback? onPaymentSuccess;

  const BankilyPaymentScreen({
    super.key,
    required this.amount,
    required this.paymentType,
    this.orderId,
    this.onPaymentSuccess,
  });

  @override
  State<BankilyPaymentScreen> createState() => _BankilyPaymentScreenState();
}

class _BankilyPaymentScreenState extends State<BankilyPaymentScreen> {
  final _phoneController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _bankilyService = BankilyService();
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;
  bool _paymentSuccess = false;
  String? _errorMessage;
  String? _transactionId;

  @override
  void dispose() {
    _phoneController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(BankilyConfig.brandColor),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isProcessing ? null : () => Get.back(result: false),
        ),
        title: Text(
          'الدفع عبر بنكيلي',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _paymentSuccess ? _buildSuccessView() : _buildPaymentForm(),
    );
  }

  /// Build the payment form
  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Amount header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(BankilyConfig.brandColor),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'المبلغ المطلوب',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Constant.amountShow(amount: widget.amount.toString()),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'خطوات الدفع عبر B-PAY',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildStep('1', 'افتح تطبيق Bankily'),
                  _buildStep('2', 'اختر B-PAY من القائمة الرئيسية'),
                  _buildStep(
                      '3', 'أدخل رمز التاجر: ${BankilyConfig.merchantCode}'),
                  _buildStep('4',
                      'أدخل المبلغ: ${Constant.amountShow(amount: widget.amount.toString())}'),
                  _buildStep('5', 'أكد الدفع وأدخل رمز PIN'),
                  _buildStep('6', 'ستحصل على رمز التحقق (passcode)'),
                  _buildStep('7', 'أدخل رقم هاتفك ورمز التحقق أدناه'),
                ],
              ),
            ),
          ),

          // Merchant code box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(BankilyConfig.brandColor), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        'رمز التاجر',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        BankilyConfig.merchantCode,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(
                          text: BankilyConfig.merchantCode));
                      ShowToastDialog.showToast('تم نسخ رمز التاجر');
                    },
                    icon: const Icon(
                      Icons.copy,
                      color: Color(BankilyConfig.brandColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Phone + Passcode form
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'بيانات الدفع',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Phone number field
                  Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: ui.TextDirection.ltr,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: InputDecoration(
                        labelText: 'رقم هاتف',
                        prefixIcon: const Icon(Icons.phone,
                            color: Color(BankilyConfig.brandColor)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(BankilyConfig.brandColor), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم الهاتف';
                        }
                        if (value.length < 8) {
                          return 'رقم الهاتف يجب أن يكون 8 أرقام';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Passcode field
                  Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: TextFormField(
                      controller: _passcodeController,
                      keyboardType: TextInputType.number,
                      textDirection: ui.TextDirection.ltr,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: 'رمز التحقق (Passcode)',
                        hintText: 'XXXX',
                        prefixIcon: const Icon(Icons.lock,
                            color: Color(BankilyConfig.brandColor)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(BankilyConfig.brandColor), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رمز التحقق';
                        }
                        if (value.length < 4) {
                          return 'رمز التحقق يجب أن يكون 4 أرقام';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(BankilyConfig.brandColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'جاري المعالجة...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'تأكيد الدفع',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Build success view
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(BankilyConfig.brandColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(BankilyConfig.brandColor),
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تم الدفع بنجاح!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(BankilyConfig.brandColor),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              Constant.amountShow(amount: widget.amount.toString()),
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_transactionId != null) ...[
              const SizedBox(height: 10),
              Text(
                'رقم العملية: $_transactionId',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(result: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(BankilyConfig.brandColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'تم',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build step instruction
  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(BankilyConfig.brandColor),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
              textDirection: ui.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  /// Process the Bankily B-PAY payment
  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final operationId = BankilyPaymentRequest.generateOperationId(
      widget.paymentType,
    );

    try {
      // Call Cloud Function to process payment
      final response = await _bankilyService.processPayment(
        clientPhone: _phoneController.text.trim(),
        passcode: _passcodeController.text.trim(),
        amount: widget.amount,
        operationId: operationId,
        language: 'ar',
      );

      if (response.isSuccess) {
        setState(() {
          _paymentSuccess = true;
          _transactionId = response.transactionId;
        });

        // Handle based on payment type
        if (widget.paymentType == BankilyPaymentType.walletTopUp) {
          await _bankilyService.processWalletTopUp(
            amount: widget.amount,
            operationId: operationId,
          );
        }

        // Call success callback
        widget.onPaymentSuccess?.call();

        ShowToastDialog.showToast('تم الدفع بنجاح! ✓');
      } else {
        setState(() {
          _errorMessage = response.errorMessage.isNotEmpty
              ? response.errorMessage
              : 'فشل في عملية الدفع. تأكد من البيانات وحاول مرة أخرى.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال. حاول مرة أخرى.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

/// Helper function to navigate to Bankily payment screen
Future<bool?> navigateToBankilyPayment({
  required BuildContext context,
  required double amount,
  required BankilyPaymentType paymentType,
  String? orderId,
  VoidCallback? onSuccess,
}) async {
  return await Get.to<bool>(
    () => BankilyPaymentScreen(
      amount: amount,
      paymentType: paymentType,
      orderId: orderId,
      onPaymentSuccess: onSuccess,
    ),
  );
}
