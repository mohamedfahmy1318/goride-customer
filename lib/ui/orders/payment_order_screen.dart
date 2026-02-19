import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/payment_order_controller.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/payment/bankily/bankily.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/coupon_screen/coupon_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../themes/button_them.dart';

class PaymentOrderScreen extends StatelessWidget {
  const PaymentOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<PaymentOrderController>(
        init: PaymentOrderController(),
        builder: (controller) {
          return Scaffold(
              backgroundColor: themeChange.getThem()
                  ? AppColors.darkBackground
                  : AppColors.background,
              appBar: AppBar(
                backgroundColor: themeChange.getThem()
                    ? AppColors.darkBackground
                    : Colors.white,
                title: Text("Ride Details".tr,
                    style: TextStyle(
                        color: themeChange.getThem()
                            ? Colors.white
                            : Colors.black)),
                leading: InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color:
                          themeChange.getThem() ? Colors.white : Colors.black,
                    )),
              ),
              body: Column(
                children: [
                  Container(
                    height: Responsive.width(10, context),
                    width: Responsive.width(100, context),
                    color: themeChange.getThem()
                        ? AppColors.darkBackground
                        : AppColors.background,
                  ),
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -22),
                      child: controller.isLoading.value
                          ? Constant.loader()
                          : Container(
                              decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).colorScheme.background,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25))),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: StreamBuilder(
                                    stream: FireStoreUtils.fireStore
                                        .collection(CollectionName.orders)
                                        .doc(controller.orderModel.value.id)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Something went wrong'.tr));
                                      }

                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Constant.loader();
                                      }
                                      OrderModel orderModel =
                                          OrderModel.fromJson(
                                              snapshot.data!.data()!);

                                      return SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              DriverView(
                                                  driverId: controller
                                                      .orderModel.value.driverId
                                                      .toString()),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 5),
                                                child: Divider(thickness: 1),
                                              ),
                                              Text(
                                                "Vehicle Details".tr,
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(height: 10),
                                              FutureBuilder<DriverUserModel?>(
                                                  future:
                                                      FireStoreUtils.getDriver(
                                                          controller.orderModel
                                                              .value.driverId
                                                              .toString()),
                                                  builder: (context, snapshot) {
                                                    switch (snapshot
                                                        .connectionState) {
                                                      case ConnectionState
                                                            .waiting:
                                                        return Constant
                                                            .loader();
                                                      case ConnectionState.done:
                                                        if (snapshot.hasError) {
                                                          return Text(snapshot
                                                              .error
                                                              .toString());
                                                        } else {
                                                          DriverUserModel
                                                              driverModel =
                                                              snapshot.data!;
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: themeChange
                                                                      .getThem()
                                                                  ? AppColors
                                                                      .darkContainerBackground
                                                                  : AppColors
                                                                      .containerBackground,
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .all(
                                                                      Radius.circular(
                                                                          10)),
                                                              border: Border.all(
                                                                  color: themeChange.getThem()
                                                                      ? AppColors
                                                                          .darkContainerBorder
                                                                      : AppColors
                                                                          .containerBorder,
                                                                  width: 0.5),
                                                              boxShadow:
                                                                  themeChange
                                                                          .getThem()
                                                                      ? null
                                                                      : [
                                                                          BoxShadow(
                                                                            color:
                                                                                Colors.black.withOpacity(0.10),
                                                                            blurRadius:
                                                                                5,
                                                                            offset:
                                                                                const Offset(0, 4),
                                                                          ),
                                                                        ],
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      vertical:
                                                                          12,
                                                                      horizontal:
                                                                          10),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      SvgPicture
                                                                          .asset(
                                                                        'assets/icons/ic_car.svg',
                                                                        width:
                                                                            18,
                                                                        color: themeChange.getThem()
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              10),
                                                                      Text(
                                                                        Constant.localizationName(driverModel
                                                                            .vehicleInformation!
                                                                            .vehicleType),
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      SvgPicture
                                                                          .asset(
                                                                        'assets/icons/ic_color.svg',
                                                                        width:
                                                                            18,
                                                                        color: themeChange.getThem()
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              10),
                                                                      Text(
                                                                        driverModel
                                                                            .vehicleInformation!
                                                                            .vehicleColor
                                                                            .toString(),
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      )
                                                                    ],
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Image
                                                                          .asset(
                                                                        'assets/icons/ic_number.png',
                                                                        width:
                                                                            18,
                                                                        color: themeChange.getThem()
                                                                            ? Colors.white
                                                                            : Colors.black,
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              10),
                                                                      Text(
                                                                        driverModel
                                                                            .vehicleInformation!
                                                                            .vehicleNumber
                                                                            .toString(),
                                                                        style: GoogleFonts.poppins(
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      default:
                                                        return Text('Error'.tr);
                                                    }
                                                  }),
                                              const SizedBox(height: 20),
                                              Text(
                                                "Pickup and drop-off locations"
                                                    .tr,
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: themeChange.getThem()
                                                      ? AppColors
                                                          .darkContainerBackground
                                                      : AppColors
                                                          .containerBackground,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(10)),
                                                  border: Border.all(
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppColors
                                                              .darkContainerBorder
                                                          : AppColors
                                                              .containerBorder,
                                                      width: 0.5),
                                                  boxShadow: themeChange
                                                          .getThem()
                                                      ? null
                                                      : [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.10),
                                                            blurRadius: 5,
                                                            offset:
                                                                const Offset(
                                                                    0, 4),
                                                          ),
                                                        ],
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: LocationView(
                                                    sourceLocation: controller
                                                        .orderModel
                                                        .value
                                                        .sourceLocationName
                                                        .toString(),
                                                    destinationLocation: controller
                                                        .orderModel
                                                        .value
                                                        .destinationLocationName
                                                        .toString(),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 20),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppColors.darkGray
                                                          : AppColors.gray,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  10))),
                                                  child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 12),
                                                      child: Center(
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                                child: Text(
                                                                    orderModel
                                                                        .status
                                                                        .toString(),
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight.w500))),
                                                            Text(
                                                                Constant().formatTimestamp(
                                                                    orderModel
                                                                        .createdDate),
                                                                style: GoogleFonts
                                                                    .poppins()),
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: themeChange.getThem()
                                                      ? AppColors
                                                          .darkContainerBackground
                                                      : AppColors
                                                          .containerBackground,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(10)),
                                                  border: Border.all(
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppColors
                                                              .darkContainerBorder
                                                          : AppColors
                                                              .containerBorder,
                                                      width: 0.5),
                                                  boxShadow: themeChange
                                                          .getThem()
                                                      ? null
                                                      : [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.10),
                                                            blurRadius: 5,
                                                            offset:
                                                                const Offset(
                                                                    0, 4),
                                                          ),
                                                        ],
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: InkWell(
                                                    onTap: () {
                                                      Get.to(const CouponScreen())!
                                                          .then((value) {
                                                        if (value != null) {
                                                          controller
                                                              .selectedCouponModel
                                                              .value = value;
                                                          if (controller
                                                                  .selectedCouponModel
                                                                  .value
                                                                  .type ==
                                                              "fix") {
                                                            controller
                                                                .couponAmount
                                                                .value = double
                                                                    .parse(controller
                                                                        .selectedCouponModel
                                                                        .value
                                                                        .amount
                                                                        .toString())
                                                                .toStringAsFixed(Constant
                                                                    .currencyModel!
                                                                    .decimalDigits!);
                                                          } else {
                                                            controller
                                                                .couponAmount
                                                                .value = ((double.parse(controller
                                                                            .selectedCouponModel
                                                                            .value
                                                                            .amount
                                                                            .toString()) *
                                                                        controller
                                                                            .subTotal
                                                                            .value) /
                                                                    100)
                                                                .toStringAsFixed(Constant
                                                                    .currencyModel!
                                                                    .decimalDigits!);
                                                          }
                                                          controller
                                                              .calculateAmount();
                                                        }
                                                      });
                                                    },
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Image.asset(
                                                          'assets/icons/ic_offer.png',
                                                          width: 50,
                                                          height: 50,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "Redeem Coupon"
                                                                    .tr,
                                                                style: GoogleFonts.poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700),
                                                              ),
                                                              Text(
                                                                "Add coupon code"
                                                                    .tr,
                                                                style: GoogleFonts
                                                                    .poppins(),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SvgPicture.asset(
                                                          "assets/icons/ic_add_offer.svg",
                                                          width: 40,
                                                          height: 40,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: themeChange.getThem()
                                                      ? AppColors
                                                          .darkContainerBackground
                                                      : AppColors
                                                          .containerBackground,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(10)),
                                                  border: Border.all(
                                                      color: themeChange
                                                              .getThem()
                                                          ? AppColors
                                                              .darkContainerBorder
                                                          : AppColors
                                                              .containerBorder,
                                                      width: 0.5),
                                                  boxShadow: themeChange
                                                          .getThem()
                                                      ? null
                                                      : [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.10),
                                                            blurRadius: 5,
                                                            offset:
                                                                const Offset(
                                                                    0, 4),
                                                          ),
                                                        ],
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Booking summary"
                                                                  .tr,
                                                              style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(
                                                          thickness: 1),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Ride Amount".tr,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      color: AppColors
                                                                          .subTitleColor),
                                                            ),
                                                          ),
                                                          Text(
                                                            Constant.amountShow(
                                                                amount: controller
                                                                    .amount
                                                                    .value
                                                                    .toString()),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Minute charge"
                                                                  .tr,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      color: AppColors
                                                                          .subTitleColor),
                                                            ),
                                                          ),
                                                          Text(
                                                            Constant.amountShow(
                                                                amount: controller
                                                                    .totalChargeOfMinute
                                                                    .value
                                                                    .toString()),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Base Fare".tr,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      color: AppColors
                                                                          .subTitleColor),
                                                            ),
                                                          ),
                                                          Text(
                                                            Constant.amountShow(
                                                                amount: controller
                                                                    .basicFareCharge
                                                                    .value
                                                                    .toString()),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Holding Charge"
                                                                  .tr,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      color: AppColors
                                                                          .subTitleColor),
                                                            ),
                                                          ),
                                                          Text(
                                                            Constant.amountShow(
                                                                amount: controller
                                                                    .holdingCharge
                                                                    .value
                                                                    .toString()),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(
                                                          thickness: 1),
                                                      controller
                                                                  .orderModel
                                                                  .value
                                                                  .taxList ==
                                                              null
                                                          ? const SizedBox()
                                                          : ListView.builder(
                                                              itemCount:
                                                                  controller
                                                                      .orderModel
                                                                      .value
                                                                      .taxList!
                                                                      .length,
                                                              shrinkWrap: true,
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                TaxModel
                                                                    taxModel =
                                                                    controller
                                                                        .orderModel
                                                                        .value
                                                                        .taxList![index];
                                                                return Column(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            "${taxModel.title.toString()} (${taxModel.type == "fix" ? Constant.amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                                                                            style:
                                                                                GoogleFonts.poppins(color: AppColors.subTitleColor),
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          Constant.amountShow(
                                                                              amount: Constant().calculateTax(amount: (double.parse(controller.subTotal.value.toString()) - double.parse(controller.couponAmount.value.toString())).toString(), taxModel: taxModel).toString()),
                                                                          style:
                                                                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const Divider(
                                                                        thickness:
                                                                            1),
                                                                  ],
                                                                );
                                                              },
                                                            ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Discount".tr,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                      color: AppColors
                                                                          .subTitleColor),
                                                            ),
                                                          ),
                                                          Text(
                                                            "(-${controller.couponAmount.value == "0.0" ? Constant.amountShow(amount: "0.0") : Constant.amountShow(amount: controller.couponAmount.value)})",
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Colors
                                                                        .red),
                                                          ),
                                                        ],
                                                      ),
                                                      const Divider(
                                                          thickness: 1),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "Payable amount"
                                                                  .tr,
                                                              style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                          ),
                                                          Text(
                                                            Constant.amountShow(
                                                                amount: controller
                                                                    .total
                                                                    .toString()),
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              ButtonThem.buildButton(
                                                context,
                                                title: "ادفع عبر Bankily".tr,
                                                onPress: () async {
                                                  // Navigate directly to Bankily payment
                                                  final result =
                                                      await navigateToBankilyPayment(
                                                    context: context,
                                                    amount:
                                                        controller.total.value,
                                                    paymentType:
                                                        BankilyPaymentType
                                                            .ridePayment,
                                                    orderId: controller
                                                        .orderModel.value.id,
                                                    onSuccess: () {
                                                      controller
                                                          .selectedPaymentMethod
                                                          .value = "Bankily";
                                                      controller
                                                          .completeOrder();
                                                    },
                                                  );

                                                  if (result != true) {
                                                    // Payment cancelled or failed
                                                    ShowToastDialog.showToast(
                                                        'تم إلغاء الدفع أو فشل. حاول مرة أخرى.'
                                                            .tr);
                                                  }
                                                },
                                              ),
                                              const SizedBox(height: 10),
                                              ButtonThem.buildButton(
                                                context,
                                                title:
                                                    "ادفع من المحفظة (${Constant.amountShow(amount: controller.userModel.value.walletAmount?.toString() ?? '0')})",
                                                onPress: () async {
                                                  controller
                                                      .completeWalletOrder();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ),
                    ),
                  ),
                ],
              ));
        });
  }
}
