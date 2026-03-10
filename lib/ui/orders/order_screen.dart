import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/chat_screen/chat_screen.dart';
import 'package:customer/ui/hold_timer/hold_timer_screen.dart';
import 'package:customer/ui/orders/complete_order_screen.dart';
import 'package:customer/ui/orders/live_tracking_screen.dart';
import 'package:customer/ui/orders/order_details_screen.dart';
import 'package:customer/ui/orders/payment_order_screen.dart';
import 'package:customer/ui/review/review_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/driver_view.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
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
            child: Container(
              decoration: BoxDecoration(
                  color: themeChange.getThem()
                      ? AppColors.darkBackground
                      : AppColors.background,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TabBar(
                          indicatorColor: AppColors.darkModePrimary,
                          tabs: [
                            Tab(
                                child: Text(
                              "Active Rides".tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(),
                            )),
                            Tab(
                                child: Text(
                              "Completed Rides".tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(),
                            )),
                            Tab(
                                child: Text(
                              "Canceled Rides".tr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(),
                            )),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FireStoreUtils.fireStore
                                    .collection(CollectionName.orders)
                                    .where("userId",
                                        isEqualTo:
                                            FireStoreUtils.getCurrentUid())
                                    .where("status", whereIn: [
                                      Constant.ridePlaced,
                                      Constant.rideInProgress,
                                      Constant.rideComplete,
                                      Constant.rideActive,
                                      Constant.rideDriverArrived,
                                      Constant.rideHoldAccepted,
                                      Constant.rideHold,
                                    ])
                                    .where("paymentStatus", isEqualTo: false)
                                    .orderBy("createdDate", descending: true)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Something went wrong'.tr));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Constant.loader();
                                  }
                                  return snapshot.data!.docs.isEmpty
                                      ? Center(
                                          child:
                                              Text("No active rides Found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            OrderModel orderModel =
                                                OrderModel.fromJson(snapshot
                                                        .data!.docs[index]
                                                        .data()
                                                    as Map<String, dynamic>);

                                            return InkWell(
                                              onTap: () {
                                                Get.to(
                                                    const CompleteOrderScreen(),
                                                    arguments: {
                                                      "orderModel": orderModel,
                                                    });
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: themeChange.getThem()
                                                        ? AppColors
                                                            .darkContainerBackground
                                                        : AppColors
                                                            .containerBackground,
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    border: Border.all(
                                                        color: themeChange
                                                                .getThem()
                                                            ? AppColors
                                                                .darkContainerBorder
                                                            : AppColors
                                                                .containerBorder,
                                                        width: 0.5),
                                                    boxShadow:
                                                        themeChange.getThem()
                                                            ? null
                                                            : [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.10),
                                                                  blurRadius: 5,
                                                                  offset: const Offset(
                                                                      0,
                                                                      4), // changes position of shadow
                                                                ),
                                                              ],
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        orderModel.status ==
                                                                    Constant
                                                                        .rideComplete ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideActive ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideDriverArrived
                                                            ? const SizedBox()
                                                            : Row(
                                                                children: [
                                                                  Expanded(
                                                                    child: Text(
                                                                      orderModel
                                                                          .status
                                                                          .toString()
                                                                          .tr,
                                                                      style: GoogleFonts.poppins(
                                                                          fontWeight:
                                                                              FontWeight.w500),
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    orderModel.status ==
                                                                            Constant
                                                                                .ridePlaced
                                                                        ? Constant.amountShow(
                                                                            amount: double.parse(orderModel.offerRate.toString()).toStringAsFixed(Constant
                                                                                .currencyModel!.decimalDigits!))
                                                                        : Constant.amountShow(
                                                                            amount:
                                                                                double.parse(orderModel.finalRate.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)),
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                ],
                                                              ),
                                                        orderModel.status ==
                                                                    Constant
                                                                        .rideComplete ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideActive ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideDriverArrived
                                                            ? Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            10),
                                                                child:
                                                                    DriverView(
                                                                  driverId: orderModel
                                                                      .driverId
                                                                      .toString(),
                                                                ),
                                                              )
                                                            : Container(),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        LocationView(
                                                          sourceLocation: orderModel
                                                              .sourceLocationName
                                                              .toString(),
                                                          destinationLocation:
                                                              orderModel
                                                                  .destinationLocationName
                                                                  .toString(),
                                                        ),
                                                        const SizedBox(
                                                          height: 5,
                                                        ),
                                                        orderModel.someOneElse !=
                                                                null
                                                            ? Container(
                                                                decoration: BoxDecoration(
                                                                    color: themeChange.getThem()
                                                                        ? AppColors
                                                                            .darkGray
                                                                        : AppColors
                                                                            .gray,
                                                                    borderRadius:
                                                                        const BorderRadius
                                                                            .all(
                                                                            Radius.circular(10))),
                                                                child: Padding(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            10),
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Text(orderModel.someOneElse!.fullName.toString().tr, style: GoogleFonts.poppins()),
                                                                              Text(orderModel.someOneElse!.contactNumber.toString().tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        InkWell(
                                                                            onTap:
                                                                                () async {
                                                                              await Share.share(
                                                                                subject: 'Ride Booked'.tr,
                                                                                'Your ride is booked. Enjoy your ride!'.tr,
                                                                              );
                                                                            },
                                                                            child:
                                                                                const Icon(Icons.share))
                                                                      ],
                                                                    )),
                                                              )
                                                            : const SizedBox(),
                                                        if (orderModel
                                                                    .acceptHoldTime !=
                                                                null &&
                                                            orderModel.status ==
                                                                Constant
                                                                    .rideHoldAccepted)
                                                          HoldTimerWidget(
                                                            acceptHoldTime:
                                                                orderModel
                                                                    .acceptHoldTime!,
                                                            holdingMinuteCharge:
                                                                orderModel
                                                                    .service!
                                                                    .holdingMinuteCharge
                                                                    .toString(),
                                                            holdingMinute:
                                                                orderModel
                                                                    .service!
                                                                    .holdingMinute
                                                                    .toString(),
                                                            orderId:
                                                                orderModel.id!,
                                                            orderModel:
                                                                orderModel,
                                                          ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 10),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                                color: themeChange
                                                                        .getThem()
                                                                    ? AppColors
                                                                        .darkGray
                                                                    : AppColors
                                                                        .gray,
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                        Radius.circular(
                                                                            10))),
                                                            child: Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        10),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Expanded(
                                                                      child: orderModel.status == Constant.rideInProgress ||
                                                                              orderModel.status == Constant.ridePlaced ||
                                                                              orderModel.status == Constant.rideComplete
                                                                          ? Text(orderModel.status.toString().tr)
                                                                          // OTP removed - show ride status instead
                                                                          : Text(orderModel.status.toString().tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12)),
                                                                    ),
                                                                    Text(
                                                                        Constant().formatTimestamp(orderModel
                                                                            .createdDate),
                                                                        style: GoogleFonts.poppins(
                                                                            fontSize:
                                                                                12)),
                                                                  ],
                                                                )),
                                                          ),
                                                        ),
                                                        Visibility(
                                                            visible: orderModel
                                                                    .status ==
                                                                Constant
                                                                    .ridePlaced,
                                                            child: ButtonThem
                                                                .buildButton(
                                                              context,
                                                              title:
                                                                  'Searching for drivers'
                                                                      .tr,
                                                              btnHeight: 44,
                                                              onPress:
                                                                  () async {
                                                                Get.to(
                                                                    const OrderDetailsScreen(),
                                                                    arguments: {
                                                                      "orderModel":
                                                                          orderModel,
                                                                    });
                                                              },
                                                            )),
                                                        Visibility(
                                                            visible: orderModel
                                                                    .status !=
                                                                Constant
                                                                    .ridePlaced,
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child:
                                                                      InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      UserModel?
                                                                          customer =
                                                                          await FireStoreUtils.getUserProfile(orderModel
                                                                              .userId
                                                                              .toString());
                                                                      DriverUserModel?
                                                                          driver =
                                                                          await FireStoreUtils.getDriver(orderModel
                                                                              .driverId
                                                                              .toString());

                                                                      Get.to(
                                                                          ChatScreens(
                                                                        driverId:
                                                                            driver!.id,
                                                                        customerId:
                                                                            customer!.id,
                                                                        customerName:
                                                                            customer.fullName,
                                                                        customerProfileImage:
                                                                            customer.profilePic,
                                                                        driverName:
                                                                            driver.fullName,
                                                                        driverProfileImage:
                                                                            driver.profilePic,
                                                                        orderId:
                                                                            orderModel.id,
                                                                        token: driver
                                                                            .fcmToken,
                                                                      ));
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          44,
                                                                      decoration: BoxDecoration(
                                                                          color: themeChange.getThem()
                                                                              ? AppColors.darkModePrimary
                                                                              : AppColors.primary,
                                                                          borderRadius: BorderRadius.circular(5)),
                                                                      child: Icon(
                                                                          Icons
                                                                              .chat,
                                                                          color: themeChange.getThem()
                                                                              ? Colors.black
                                                                              : Colors.white),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      DriverUserModel?
                                                                          driver =
                                                                          await FireStoreUtils.getDriver(orderModel
                                                                              .driverId
                                                                              .toString());
                                                                      Constant.makePhoneCall(
                                                                          "${driver!.countryCode}${driver.phoneNumber}");
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          44,
                                                                      decoration: BoxDecoration(
                                                                          color: themeChange.getThem()
                                                                              ? AppColors.darkModePrimary
                                                                              : AppColors.primary,
                                                                          borderRadius: BorderRadius.circular(5)),
                                                                      child: Icon(
                                                                          Icons
                                                                              .call,
                                                                          color: themeChange.getThem()
                                                                              ? Colors.black
                                                                              : Colors.white),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      DriverUserModel?
                                                                          driver =
                                                                          await FireStoreUtils.getDriver(orderModel
                                                                              .driverId
                                                                              .toString());
                                                                      Constant.openWhatsApp(
                                                                          "${driver!.countryCode}${driver.phoneNumber}");
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          44,
                                                                      decoration: BoxDecoration(
                                                                          color: const Color(
                                                                              0xff25D366),
                                                                          borderRadius:
                                                                              BorderRadius.circular(5)),
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            10),
                                                                        child: SvgPicture
                                                                            .asset(
                                                                          'assets/icons/whatsapp-logo.svg',
                                                                          width:
                                                                              24,
                                                                          height:
                                                                              24,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      if (orderModel.status == Constant.rideActive ||
                                                                          orderModel.status ==
                                                                              Constant
                                                                                  .rideDriverArrived ||
                                                                          orderModel.status ==
                                                                              Constant.rideInProgress) {
                                                                        Get.to(
                                                                            const LiveTrackingScreen(),
                                                                            arguments: {
                                                                              "orderModel": orderModel,
                                                                              "type": "orderModel",
                                                                            });
                                                                      }
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height:
                                                                          44,
                                                                      decoration: BoxDecoration(
                                                                          color: themeChange.getThem()
                                                                              ? AppColors.darkModePrimary
                                                                              : AppColors.primary,
                                                                          borderRadius: BorderRadius.circular(5)),
                                                                      child: Icon(
                                                                          Icons
                                                                              .map,
                                                                          color: themeChange.getThem()
                                                                              ? Colors.black
                                                                              : Colors.white),
                                                                    ),
                                                                  ),
                                                                )
                                                              ],
                                                            )),
                                                        // Track Driver button for rideActive / rideDriverArrived
                                                        Visibility(
                                                            visible: orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideActive ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideDriverArrived,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 10),
                                                              child: ButtonThem
                                                                  .buildButton(
                                                                context,
                                                                title:
                                                                    "Track Driver"
                                                                        .tr,
                                                                btnHeight: 44,
                                                                onPress:
                                                                    () async {
                                                                  Get.to(
                                                                      const LiveTrackingScreen(),
                                                                      arguments: {
                                                                        "orderModel":
                                                                            orderModel,
                                                                        "type":
                                                                            "orderModel",
                                                                      });
                                                                },
                                                              ),
                                                            )),
                                                        // Cancel Ride button for rideActive / rideDriverArrived
                                                        Visibility(
                                                            visible: orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideActive ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideDriverArrived,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      top: 10),
                                                              child: ButtonThem
                                                                  .roundButton(
                                                                context,
                                                                title:
                                                                    "إلغاء الرحلة"
                                                                        .tr,
                                                                btnHeight: 44,
                                                                btnColor:
                                                                    Colors.red,
                                                                txtColor: Colors
                                                                    .white,
                                                                onPress:
                                                                    () async {
                                                                  _showCancelRideDialog(
                                                                      context,
                                                                      orderModel);
                                                                },
                                                              ),
                                                            )),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Visibility(
                                                            visible: orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideInProgress ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideHold ||
                                                                orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideHoldAccepted,
                                                            child: ButtonThem
                                                                .buildButton(
                                                              context,
                                                              title: "SOS".tr,
                                                              btnHeight: 44,
                                                              onPress:
                                                                  () async {
                                                                await FireStoreUtils.getSOS(
                                                                        orderModel
                                                                            .id
                                                                            .toString())
                                                                    .then(
                                                                        (value) {
                                                                  if (value !=
                                                                      null) {
                                                                    ShowToastDialog
                                                                        .showToast(
                                                                            "Your request is ${value.status}");
                                                                  } else {
                                                                    SosModel
                                                                        sosModel =
                                                                        SosModel();
                                                                    sosModel.id =
                                                                        Constant
                                                                            .getUuid();
                                                                    sosModel.orderId =
                                                                        orderModel
                                                                            .id;
                                                                    sosModel.status =
                                                                        "Initiated";
                                                                    sosModel.orderType =
                                                                        "city";
                                                                    FireStoreUtils
                                                                        .setSOS(
                                                                            sosModel);
                                                                  }
                                                                });
                                                              },
                                                            )),
                                                        orderModel.status ==
                                                                Constant
                                                                    .rideInProgress
                                                            ? const SizedBox(
                                                                height: 10,
                                                              )
                                                            : SizedBox.shrink(),
                                                        Visibility(
                                                            visible: orderModel
                                                                        .status ==
                                                                    Constant
                                                                        .rideInProgress &&
                                                                (orderModel
                                                                        .service
                                                                        ?.enableHoldingCharge ??
                                                                    true) &&
                                                                (orderModel.totalHoldingCharges ==
                                                                        null ||
                                                                    orderModel
                                                                            .totalHoldingCharges ==
                                                                        "0.0"),
                                                            child: ButtonThem
                                                                .buildButton(
                                                              context,
                                                              title: "HOLD".tr,
                                                              btnHeight: 44,
                                                              onPress:
                                                                  () async {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                          'Are you sure you want to hold the ride?'
                                                                              .tr),
                                                                      actions: [
                                                                        SizedBox(
                                                                          height:
                                                                              5,
                                                                        ),
                                                                        TextButton(
                                                                          onPressed:
                                                                              () async {
                                                                            Navigator.of(context).pop();
                                                                          },
                                                                          child: Container(
                                                                              height: 40,
                                                                              width: 70,
                                                                              color: Colors.black,
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.only(top: 12.0),
                                                                                child: Text(
                                                                                  'No',
                                                                                  textAlign: TextAlign.center,
                                                                                  style: TextStyle(
                                                                                    color: Colors.white,
                                                                                  ),
                                                                                ),
                                                                              )),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed:
                                                                              () async {
                                                                            ShowToastDialog.showLoader("Please wait".tr);
                                                                            orderModel.status =
                                                                                Constant.rideHold;
                                                                            await FireStoreUtils.setOrder(orderModel).then((value) {
                                                                              if (value == true) {
                                                                                ShowToastDialog.closeLoader();
                                                                                ShowToastDialog.showToast("Ride on Hold".tr);
                                                                              }
                                                                            });
                                                                            Get.back();
                                                                          },
                                                                          child: Container(
                                                                              height: 40,
                                                                              width: 70,
                                                                              color: Colors.black,
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.only(top: 12.0),
                                                                                child: Text('Yes'.tr, textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                                                                              )),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                            )),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        // Show Pay button only for non-cash completed rides
                                                        // Cash payment is confirmed by driver only
                                                        Visibility(
                                                            visible: orderModel.status ==
                                                                    Constant
                                                                        .rideComplete &&
                                                                (orderModel.paymentStatus ==
                                                                        null ||
                                                                    orderModel
                                                                            .paymentStatus ==
                                                                        false) &&
                                                                orderModel
                                                                        .paymentType !=
                                                                    "Cash",
                                                            child: ButtonThem
                                                                .buildButton(
                                                              context,
                                                              title: "Pay".tr,
                                                              btnHeight: 44,
                                                              onPress:
                                                                  () async {
                                                                Get.to(
                                                                    const PaymentOrderScreen(),
                                                                    arguments: {
                                                                      "orderModel":
                                                                          orderModel,
                                                                    });
                                                              },
                                                            )),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FireStoreUtils.fireStore
                                    .collection(CollectionName.orders)
                                    .where("userId",
                                        isEqualTo:
                                            FireStoreUtils.getCurrentUid())
                                    .where("status",
                                        isEqualTo: Constant.rideComplete)
                                    .where("paymentStatus", isEqualTo: true)
                                    .orderBy("createdDate", descending: true)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Something went wrong'.tr));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Constant.loader();
                                  }
                                  return snapshot.data!.docs.isEmpty
                                      ? Center(
                                          child: Text(
                                              "No completed rides Found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            OrderModel orderModel =
                                                OrderModel.fromJson(snapshot
                                                        .data!.docs[index]
                                                        .data()
                                                    as Map<String, dynamic>);
                                            return Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Container(
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
                                                            offset: const Offset(
                                                                0,
                                                                4), // changes position of shadow
                                                          ),
                                                        ],
                                                ),
                                                child: InkWell(
                                                    onTap: () {
                                                      Get.to(
                                                          const CompleteOrderScreen(),
                                                          arguments: {
                                                            "orderModel":
                                                                orderModel,
                                                          });
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          DriverView(
                                                            driverId: orderModel
                                                                .driverId
                                                                .toString(),
                                                          ),
                                                          const Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    vertical:
                                                                        4),
                                                            child: Divider(
                                                              thickness: 1,
                                                            ),
                                                          ),
                                                          LocationView(
                                                            sourceLocation:
                                                                orderModel
                                                                    .sourceLocationName
                                                                    .toString(),
                                                            destinationLocation:
                                                                orderModel
                                                                    .destinationLocationName
                                                                    .toString(),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        14),
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                  color: themeChange.getThem()
                                                                      ? AppColors
                                                                          .darkGray
                                                                      : AppColors
                                                                          .gray,
                                                                  borderRadius:
                                                                      const BorderRadius
                                                                          .all(
                                                                          Radius.circular(
                                                                              10))),
                                                              child: Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          12),
                                                                  child: Center(
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                            child:
                                                                                Text(orderModel.status.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                                                                        Text(
                                                                            Constant().formatTimestamp(orderModel
                                                                                .createdDate),
                                                                            style:
                                                                                GoogleFonts.poppins()),
                                                                      ],
                                                                    ),
                                                                  )),
                                                            ),
                                                          ),
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                  child: ButtonThem
                                                                      .buildButton(
                                                                context,
                                                                title:
                                                                    "Review".tr,
                                                                btnHeight: 44,
                                                                onPress:
                                                                    () async {
                                                                  Get.to(
                                                                      const ReviewScreen(),
                                                                      arguments: {
                                                                        "type":
                                                                            "orderModel",
                                                                        "orderModel":
                                                                            orderModel,
                                                                      });
                                                                },
                                                              )),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                              ),
                                            );
                                          });
                                },
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: FireStoreUtils.fireStore
                                    .collection(CollectionName.orders)
                                    .where("userId",
                                        isEqualTo:
                                            FireStoreUtils.getCurrentUid())
                                    .where("status",
                                        isEqualTo: Constant.rideCanceled)
                                    .orderBy("createdDate", descending: true)
                                    .snapshots(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text('Something went wrong'.tr));
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Constant.loader();
                                  }
                                  return snapshot.data!.docs.isEmpty
                                      ? Center(
                                          child: Text(
                                              "No completed rides Found".tr),
                                        )
                                      : ListView.builder(
                                          itemCount: snapshot.data!.docs.length,
                                          scrollDirection: Axis.vertical,
                                          shrinkWrap: true,
                                          itemBuilder: (context, index) {
                                            OrderModel orderModel =
                                                OrderModel.fromJson(snapshot
                                                        .data!.docs[index]
                                                        .data()
                                                    as Map<String, dynamic>);
                                            return Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Container(
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
                                                            offset: const Offset(
                                                                0,
                                                                4), // changes position of shadow
                                                          ),
                                                        ],
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      orderModel.status ==
                                                                  Constant
                                                                      .rideComplete ||
                                                              orderModel
                                                                      .status ==
                                                                  Constant
                                                                      .rideActive ||
                                                              orderModel
                                                                      .status ==
                                                                  Constant
                                                                      .rideDriverArrived
                                                          ? const SizedBox()
                                                          : Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    orderModel
                                                                        .status
                                                                        .toString(),
                                                                    style: GoogleFonts.poppins(
                                                                        fontWeight:
                                                                            FontWeight.w500),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  Constant.amountShow(
                                                                      amount: double.parse(orderModel
                                                                              .offerRate
                                                                              .toString())
                                                                          .toStringAsFixed(Constant
                                                                              .currencyModel!
                                                                              .decimalDigits!)),
                                                                  style: GoogleFonts.poppins(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              ],
                                                            ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      LocationView(
                                                        sourceLocation: orderModel
                                                            .sourceLocationName
                                                            .toString(),
                                                        destinationLocation:
                                                            orderModel
                                                                .destinationLocationName
                                                                .toString(),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                              color: themeChange
                                                                      .getThem()
                                                                  ? AppColors
                                                                      .darkGray
                                                                  : AppColors
                                                                      .gray,
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .all(
                                                                      Radius.circular(
                                                                          10))),
                                                          child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          10),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Expanded(
                                                                      child: Text(orderModel
                                                                          .status
                                                                          .toString())),
                                                                  Text(
                                                                      Constant().formatTimestamp(
                                                                          orderModel
                                                                              .createdDate),
                                                                      style: GoogleFonts.poppins(
                                                                          fontSize:
                                                                              12)),
                                                                ],
                                                              )),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                },
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showCancelRideDialog(BuildContext context, OrderModel orderModel) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              'Cancel Ride'.tr,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this ride?'.tr,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'No'.tr,
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              ShowToastDialog.showLoader('Canceling ride...'.tr);

              orderModel.status = Constant.rideCanceled;

              // Notify driver about cancellation
              if (orderModel.driverId != null &&
                  orderModel.driverId!.isNotEmpty) {
                DriverUserModel? driver = await FireStoreUtils.getDriver(
                    orderModel.driverId.toString());
                if (driver != null && driver.fcmToken != null) {
                  Map<String, dynamic> playLoad = <String, dynamic>{
                    "type": "city_order_canceled",
                    "orderId": orderModel.id,
                  };
                  await SendNotification.sendOneNotification(
                    token: driver.fcmToken.toString(),
                    title: 'Ride Canceled'.tr,
                    titleAr:
                        '\u062a\u0645 \u0625\u0644\u063a\u0627\u0621 \u0627\u0644\u0631\u062d\u0644\u0629',
                    body: 'The customer has canceled the ride.',
                    bodyAr:
                        '\u0642\u0627\u0645 \u0627\u0644\u0639\u0645\u064a\u0644 \u0628\u0625\u0644\u063a\u0627\u0621 \u0627\u0644\u0631\u062d\u0644\u0629.',
                    payload: playLoad,
                    recipientId: driver.id,
                    recipientType: 'driver',
                  );
                }
              }

              await FireStoreUtils.setOrder(orderModel).then((value) {
                ShowToastDialog.closeLoader();
                if (value == true) {
                  ShowToastDialog.showToast('Ride canceled successfully'.tr);
                }
              });
            },
            child: Text(
              'Yes, Cancel'.tr,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}
