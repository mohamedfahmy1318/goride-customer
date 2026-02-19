import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletController extends GetxController {
  Rx<TextEditingController> amountController = TextEditingController().obs;
  Rx<PaymentModel> paymentModel = PaymentModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxString selectedPaymentMethod = "".obs;

  RxBool isLoading = true.obs;
  RxList transactionList = <WalletTransactionModel>[].obs;

  @override
  void onInit() {
    getPaymentData();
    super.onInit();
  }

  getPaymentData() async {
    getTraction();
    getUser();
    await FireStoreUtils().getPayment().then((value) {
      if (value != null) {
        paymentModel.value = value;
      }
    });

    isLoading.value = false;
    update();
  }

  getUser() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
  }

  getTraction() async {
    await FireStoreUtils.getWalletTransaction().then((value) {
      if (value != null) {
        transactionList.value = value;
      }
    });
  }

  walletTopUp() async {
    WalletTransactionModel transactionModel = WalletTransactionModel(
        id: Constant.getUuid(),
        amount: amountController.value.text,
        createdDate: Timestamp.now(),
        paymentType: selectedPaymentMethod.value,
        transactionId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: FireStoreUtils.getCurrentUid(),
        userType: "customer",
        note: "Wallet Topup");

    await FireStoreUtils.setWalletTransaction(transactionModel)
        .then((value) async {
      if (value == true) {
        await FireStoreUtils.updateUserWallet(
                amount: amountController.value.text)
            .then((value) {
          getUser();
          getTraction();
        });
      }
    });

    ShowToastDialog.showToast("Amount added in your wallet.");
  }
}
