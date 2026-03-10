import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:customer/widget/place_picker_osm.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<HomeController>(
        init: HomeController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor:
                themeChange.getThem() ? AppColors.darkBackground : Colors.white,
            body: controller.isLoading.value
                ? Constant.loader()
                : Column(
                    children: [
                      SizedBox(
                        height: Responsive.width(22, context),
                        width: Responsive.width(100, context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  controller.userModel.value.fullName
                                      .toString(),
                                  style: GoogleFonts.poppins(
                                      color: themeChange.getThem()
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18,
                                      letterSpacing: 1)),
                              const SizedBox(
                                height: 4,
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                      'assets/icons/ic_location.svg',
                                      width: 16,
                                      colorFilter: ColorFilter.mode(
                                          themeChange.getThem()
                                              ? Colors.white
                                              : Colors.black,
                                          BlendMode.srcIn)),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                      child: Text(
                                          controller.currentLocation.value,
                                          style: GoogleFonts.poppins(
                                              color: themeChange.getThem()
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.w400))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.background,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Visibility(
                                      visible: controller.bannerList.isNotEmpty,
                                      child: SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.20,
                                          child: PageView.builder(
                                              padEnds: false,
                                              itemCount:
                                                  controller.bannerList.length,
                                              scrollDirection: Axis.horizontal,
                                              controller:
                                                  controller.pageController,
                                              itemBuilder: (context, index) {
                                                BannerModel bannerModel =
                                                    controller
                                                        .bannerList[index];
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        Constant.safeImageUrl(
                                                            bannerModel.image),
                                                    imageBuilder: (context,
                                                            imageProvider) =>
                                                        Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        image: DecorationImage(
                                                            image:
                                                                imageProvider,
                                                            fit: BoxFit.cover),
                                                      ),
                                                    ),
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    placeholder: (context,
                                                            url) =>
                                                        const Center(
                                                            child:
                                                                CircularProgressIndicator()),
                                                    fit: BoxFit.cover,
                                                  ),
                                                );
                                              })),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text("Where you want to go?".tr,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            letterSpacing: 1)),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    controller.sourceLocationLAtLng.value
                                                .latitude ==
                                            null
                                        ? TextFieldThem.buildTextFiled(context,
                                            hintText:
                                                'Getting your location...'.tr,
                                            controller: controller
                                                .sourceLocationController.value,
                                            enable: false)
                                        : Row(
                                            children: [
                                              Column(
                                                children: [
                                                  SvgPicture.asset(
                                                      themeChange.getThem()
                                                          ? 'assets/icons/ic_source_dark.svg'
                                                          : 'assets/icons/ic_source.svg',
                                                      width: 18),
                                                  Dash(
                                                      direction: Axis.vertical,
                                                      length: Responsive.height(
                                                          6, context),
                                                      dashLength: 12,
                                                      dashColor: AppColors
                                                          .dottedDivider),
                                                  SvgPicture.asset(
                                                      themeChange.getThem()
                                                          ? 'assets/icons/ic_destination_dark.svg'
                                                          : 'assets/icons/ic_destination.svg',
                                                      width: 20),
                                                ],
                                              ),
                                              const SizedBox(
                                                width: 18,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Source location - auto-detected, read-only
                                                    TextFieldThem.buildTextFiled(
                                                        context,
                                                        hintText:
                                                            'Your current location'
                                                                .tr,
                                                        controller: controller
                                                            .sourceLocationController
                                                            .value,
                                                        enable: false),
                                                    SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                1, context)),
                                                    InkWell(
                                                        onTap: () async {
                                                          log("::::::::::11::::::::::::");
                                                          if (Constant
                                                                  .selectedMapType ==
                                                              'osm') {
                                                            Get.to(() =>
                                                                    const LocationPicker())
                                                                ?.then(
                                                                    (value) async {
                                                              if (value !=
                                                                  null) {
                                                                controller
                                                                        .destinationLocationController
                                                                        .value
                                                                        .text =
                                                                    value
                                                                        .displayName!;
                                                                controller
                                                                        .destinationLocationLAtLng
                                                                        .value =
                                                                    LocationLatLng(
                                                                        latitude:
                                                                            value
                                                                                .lat,
                                                                        longitude:
                                                                            value.lon);
                                                                await controller
                                                                    .calculateDurationAndDistance();
                                                                controller
                                                                    .calculateAmount();
                                                              }
                                                            });
                                                          } else {
                                                            await Navigator
                                                                .push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        PlacePicker(
                                                                  apiKey: Constant
                                                                      .mapAPIKey,
                                                                  pinBuilder: (context,
                                                                          state) =>
                                                                      const SizedBox
                                                                          .shrink(),
                                                                  onPlacePicked:
                                                                      (result) async {
                                                                    Get.back();
                                                                    controller
                                                                            .destinationLocationController
                                                                            .value
                                                                            .text =
                                                                        result
                                                                            .formattedAddress
                                                                            .toString();
                                                                    controller.destinationLocationLAtLng.value = LocationLatLng(
                                                                        latitude: result
                                                                            .geometry!
                                                                            .location
                                                                            .lat,
                                                                        longitude: result
                                                                            .geometry!
                                                                            .location
                                                                            .lng);
                                                                    await controller
                                                                        .calculateDurationAndDistance();
                                                                    controller
                                                                        .calculateAmount();
                                                                  },
                                                                  // Global search - no region restriction
                                                                  initialPosition:
                                                                      const LatLng(
                                                                          -33.8567844,
                                                                          151.213108),
                                                                  useCurrentLocation:
                                                                      true,
                                                                  autocompleteComponents: [],
                                                                  selectInitialPosition:
                                                                      true,
                                                                  usePinPointingSearch:
                                                                      false,
                                                                  usePlaceDetailSearch:
                                                                      true,
                                                                  zoomGesturesEnabled:
                                                                      true,
                                                                  zoomControlsEnabled:
                                                                      true,
                                                                  resizeToAvoidBottomInset:
                                                                      false, // only works in page mode, less flickery, remove if wrong offsets
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: TextFieldThem.buildTextFiled(
                                                                  context,
                                                                  hintText:
                                                                      'Enter destination Location'
                                                                          .tr,
                                                                  controller:
                                                                      controller
                                                                          .destinationLocationController
                                                                          .value,
                                                                  enable:
                                                                      false),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            InkWell(
                                                                onTap: () {
                                                                  ariPortDialog(
                                                                      context,
                                                                      controller,
                                                                      false);
                                                                },
                                                                child: const Icon(
                                                                    Icons
                                                                        .flight_takeoff))
                                                          ],
                                                        )),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    // "Metered Ride" button - ride without destination
                                    // Customer books without choosing destination, fare calculated by actual distance & time
                                    InkWell(
                                      onTap: () async {
                                        // Show confirmation dialog for metered ride
                                        _showMeteredRideDialog(
                                            context, controller);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.local_taxi_outlined,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "أخبر السائق",
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  Text(
                                                    "ابدأ رحلة بدون تحديد وجهة"
                                                        .tr,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: AppColors.primary
                                                          .withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: AppColors.primary,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text("Select Vehicle".tr,
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1)),
                                    const SizedBox(
                                      height: 05,
                                    ),
                                    SizedBox(
                                      height: Responsive.height(18, context),
                                      child: ListView.builder(
                                        itemCount:
                                            controller.serviceList.length,
                                        scrollDirection: Axis.horizontal,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          ServiceModel serviceModel =
                                              controller.serviceList[index];
                                          return Obx(
                                            () => InkWell(
                                              onTap: () {
                                                controller.selectedType.value =
                                                    serviceModel;
                                                controller.calculateAmount();
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(6.0),
                                                child: Container(
                                                  width: Responsive.width(
                                                      28, context),
                                                  decoration: BoxDecoration(
                                                      color: controller
                                                                  .selectedType
                                                                  .value ==
                                                              serviceModel
                                                          ? themeChange
                                                                  .getThem()
                                                              ? AppColors
                                                                  .darkModePrimary
                                                              : AppColors
                                                                  .primary
                                                          : themeChange
                                                                  .getThem()
                                                              ? AppColors
                                                                  .darkService
                                                              : controller
                                                                      .colors[
                                                                  index %
                                                                      controller
                                                                          .colors
                                                                          .length],
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(20),
                                                      )),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .background,
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                  Radius
                                                                      .circular(
                                                                          20),
                                                                )),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Transform(
                                                            alignment: Alignment
                                                                .center,
                                                            transform: Matrix4
                                                                .identity()
                                                              ..scale(
                                                                Get.locale?.languageCode ==
                                                                        'ar'
                                                                    ? -1.0
                                                                    : 1.0,
                                                                1.0,
                                                              ),
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl: Constant
                                                                  .safeImageUrl(
                                                                      serviceModel
                                                                          .image),
                                                              fit: BoxFit
                                                                  .contain,
                                                              height: Responsive
                                                                  .height(8,
                                                                      context),
                                                              width: Responsive
                                                                  .width(18,
                                                                      context),
                                                              placeholder: (context,
                                                                      url) =>
                                                                  Constant
                                                                      .loader(),
                                                              errorWidget: (context,
                                                                      url,
                                                                      error) =>
                                                                  const Icon(
                                                                      Icons
                                                                          .directions_car,
                                                                      size: 40,
                                                                      color: Colors
                                                                          .grey),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Flexible(
                                                        child: Text(
                                                          Constant
                                                              .localizationTitle(
                                                                  serviceModel
                                                                      .title),
                                                          style: GoogleFonts.poppins(
                                                              color: controller.selectedType.value == serviceModel
                                                                  ? themeChange.getThem()
                                                                      ? Colors.black
                                                                      : Colors.white
                                                                  : themeChange.getThem()
                                                                      ? Colors.white
                                                                      : Colors.black),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // تم إخفاء عرض الأسعار للعميل
                                    // Obx Price display removed
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Obx(() => Column(
                                          children: [
                                            // تم إخفاء خيار المكيف A/C
                                            // A/C option removed
                                            controller.selectedType.value
                                                        .offerRate ==
                                                    true
                                                ? const SizedBox(
                                                    height: 10,
                                                  )
                                                : SizedBox.shrink(),
                                            Visibility(
                                              visible: controller.selectedType
                                                      .value.offerRate ==
                                                  true,
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 14),
                                                decoration: BoxDecoration(
                                                  color: themeChange.getThem()
                                                      ? AppColors.darkTextField
                                                      : AppColors.textField,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: themeChange.getThem()
                                                        ? AppColors
                                                            .darkTextFieldBorder
                                                        : AppColors
                                                            .textFieldBorder,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      Constant
                                                          .currencyModel!.symbol
                                                          .toString(),
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: themeChange
                                                                .getThem()
                                                            ? Colors.white70
                                                            : Colors.black54,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        controller.amount.value
                                                                .isNotEmpty
                                                            ? controller
                                                                .amount.value
                                                            : "Offer rate".tr,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: controller
                                                                  .amount
                                                                  .value
                                                                  .isNotEmpty
                                                              ? (themeChange
                                                                      .getThem()
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black)
                                                              : Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.lock_outline,
                                                      size: 18,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        )),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        someOneTakingDialog(
                                            context, controller);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(4)),
                                          border: Border.all(
                                              color: AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 12),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                  child: Text(
                                                controller.selectedTakingRide
                                                            .value.fullName ==
                                                        "Myself"
                                                    ? "Myself".tr
                                                    : controller
                                                        .selectedTakingRide
                                                        .value
                                                        .fullName
                                                        .toString(),
                                                style: GoogleFonts.poppins(),
                                              )),
                                              const Icon(Icons
                                                  .arrow_drop_down_outlined)
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        paymentMethodDialog(
                                            context, controller);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(4)),
                                          border: Border.all(
                                              color: AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 12),
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                'assets/icons/ic_payment.svg',
                                                width: 26,
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                  child: Text(
                                                controller.selectedPaymentMethod
                                                        .value.isNotEmpty
                                                    ? controller
                                                        .selectedPaymentMethod
                                                        .value
                                                        .tr
                                                    : "Select Payment type".tr,
                                                style: GoogleFonts.poppins(),
                                              )),
                                              const Icon(Icons
                                                  .arrow_drop_down_outlined)
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    ButtonThem.buildButton(
                                      context,
                                      title: "Book Ride".tr,
                                      btnWidthRatio:
                                          Responsive.width(100, context),
                                      onPress: () async {
                                        // Prevent double-tap
                                        if (controller
                                            .isBookingInProgress.value) {
                                          return;
                                        }
                                        controller.isBookingInProgress.value =
                                            true;

                                        bool isPaymentNotCompleted =
                                            await FireStoreUtils
                                                .paymentStatusCheck();
                                        if (controller.selectedPaymentMethod
                                            .value.isEmpty) {
                                          controller.isBookingInProgress.value =
                                              false;
                                          ShowToastDialog.showToast(
                                              "Please select Payment Method"
                                                  .tr);
                                        } else if (controller
                                            .sourceLocationController
                                            .value
                                            .text
                                            .isEmpty) {
                                          controller.isBookingInProgress.value =
                                              false;
                                          ShowToastDialog.showToast(
                                              "Please select source location"
                                                  .tr);
                                        } else if (controller
                                            .destinationLocationController
                                            .value
                                            .text
                                            .isEmpty) {
                                          controller.isBookingInProgress.value =
                                              false;
                                          ShowToastDialog.showToast(
                                              "Please select destination location"
                                                  .tr);
                                        } else if ((double.tryParse(controller
                                                    .distance.value) ??
                                                0.0) <
                                            1) {
                                          controller.isBookingInProgress.value =
                                              false;
                                          ShowToastDialog.showToast(
                                              "The destination must be at least 1 km away"
                                                  .tr);
                                        } else if (isPaymentNotCompleted) {
                                          controller.isBookingInProgress.value =
                                              false;
                                          showAlertDialog(context);
                                          // showDialog(context: context, builder: (BuildContext context) => warningDailog());
                                        } else if (controller
                                                .selectedPaymentMethod.value ==
                                            "Wallet") {
                                          // Wallet: check balance >= trip amount
                                          double tripAmount = double.tryParse(
                                                  controller.amount.value) ??
                                              0.0;
                                          double walletBalance =
                                              double.tryParse(controller
                                                          .userModel
                                                          .value
                                                          .walletAmount
                                                          ?.toString() ??
                                                      '0') ??
                                                  0.0;
                                          if (walletBalance < tripAmount) {
                                            controller.isBookingInProgress
                                                .value = false;
                                            ShowToastDialog.showToast(
                                                "رصيد المحفظة غير كافي. المطلوب: ${Constant.amountShow(amount: tripAmount.toString())} - رصيدك: ${Constant.amountShow(amount: walletBalance.toString())}");
                                            return;
                                          }
                                          // Wallet has enough balance, proceed with booking
                                          await _proceedWithBooking(
                                              context, controller);
                                        } else {
                                          // Cash or other methods: proceed directly
                                          await _proceedWithBooking(
                                              context, controller);
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      height: 15,
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
        });
  }

  paymentMethodDialog(BuildContext context, HomeController controller) {
    return showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context1) {
          final themeChange = Provider.of<DarkThemeProvider>(context1);

          return FractionallySizedBox(
            heightFactor: 0.9,
            child: StatefulBuilder(builder: (context1, setState) {
              return Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: const Icon(Icons.arrow_back_ios)),
                            Expanded(
                                child: Center(
                                    child: Text(
                              "Select Payment Method".tr,
                            ))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Visibility(
                                visible: controller
                                        .paymentModel.value.cash?.enable ==
                                    true,
                                child: Obx(
                                  () => Column(
                                    children: [
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      InkWell(
                                        onTap: () {
                                          controller.selectedPaymentMethod
                                              .value = controller
                                                  .paymentModel.value.cash?.name
                                                  ?.toString() ??
                                              "";
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                                    Radius.circular(10)),
                                            border: Border.all(
                                                color: controller
                                                            .selectedPaymentMethod
                                                            .value ==
                                                        (controller
                                                                .paymentModel
                                                                .value
                                                                .cash
                                                                ?.name
                                                                ?.toString() ??
                                                            "")
                                                    ? themeChange.getThem()
                                                        ? AppColors
                                                            .darkModePrimary
                                                        : AppColors.primary
                                                    : AppColors.textFieldBorder,
                                                width: 1),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  height: 40,
                                                  width: 80,
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: AppColors
                                                              .lightGray,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5))),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(Icons.money,
                                                        color: Colors.black),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    (controller
                                                                .paymentModel
                                                                .value
                                                                .cash
                                                                ?.name
                                                                ?.toString() ??
                                                            "")
                                                        .tr,
                                                    style:
                                                        GoogleFonts.poppins(),
                                                  ),
                                                ),
                                                Radio(
                                                  value: controller.paymentModel
                                                          .value.cash?.name
                                                          ?.toString() ??
                                                      "",
                                                  groupValue: controller
                                                      .selectedPaymentMethod
                                                      .value,
                                                  activeColor:
                                                      themeChange.getThem()
                                                          ? AppColors
                                                              .darkModePrimary
                                                          : AppColors.primary,
                                                  onChanged: (value) {
                                                    controller
                                                        .selectedPaymentMethod
                                                        .value = controller
                                                            .paymentModel
                                                            .value
                                                            .cash
                                                            ?.name
                                                            ?.toString() ??
                                                        "";
                                                  },
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // ===== Wallet Payment Option =====
                              Obx(
                                () => Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () {
                                        controller.selectedPaymentMethod.value =
                                            "Wallet";
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(10)),
                                          border: Border.all(
                                              color: controller
                                                          .selectedPaymentMethod
                                                          .value ==
                                                      "Wallet"
                                                  ? themeChange.getThem()
                                                      ? AppColors
                                                          .darkModePrimary
                                                      : AppColors.primary
                                                  : AppColors.textFieldBorder,
                                              width: 1),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                height: 40,
                                                width: 80,
                                                decoration: const BoxDecoration(
                                                    color: AppColors.lightGray,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                5))),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Icon(
                                                      Icons
                                                          .account_balance_wallet,
                                                      color: Colors.black),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "المحفظة",
                                                      style:
                                                          GoogleFonts.poppins(),
                                                    ),
                                                    Text(
                                                      "الرصيد: ${Constant.amountShow(amount: controller.userModel.value.walletAmount?.toString() ?? '0')}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Radio(
                                                value: "Wallet",
                                                groupValue: controller
                                                    .selectedPaymentMethod
                                                    .value,
                                                activeColor: themeChange
                                                        .getThem()
                                                    ? AppColors.darkModePrimary
                                                    : AppColors.primary,
                                                onChanged: (value) {
                                                  controller
                                                      .selectedPaymentMethod
                                                      .value = "Wallet";
                                                },
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Bankily removed (V1)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ButtonThem.buildButton(
                        context,
                        title: "Pay".tr,
                        onPress: () async {
                          Get.back();
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }

  someOneTakingDialog(BuildContext context, HomeController controller) {
    return showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        builder: (context1) {
          final themeChange = Provider.of<DarkThemeProvider>(context1);
          return StatefulBuilder(builder: (context1, setState) {
            return Obx(
              () => Container(
                constraints:
                    BoxConstraints(maxHeight: Responsive.height(90, context)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 10),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Someone else taking this ride?".tr,
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "Choose a contact and share a code to conform that ride."
                              .tr,
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () {
                            controller.selectedTakingRide.value = ContactModel(
                                fullName: "Myself".tr, contactNumber: "");
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.all(
                                  color: controller.selectedTakingRide.value
                                              .fullName ==
                                          "Myself".tr
                                      ? themeChange.getThem()
                                          ? AppColors.darkModePrimary
                                          : AppColors.primary
                                      : AppColors.textFieldBorder,
                                  width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child:
                                        Icon(Icons.person, color: Colors.black),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Myself".tr,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                  Radio(
                                    value: "Myself",
                                    groupValue: controller
                                        .selectedTakingRide.value.fullName,
                                    activeColor: themeChange.getThem()
                                        ? AppColors.darkModePrimary
                                        : AppColors.primary,
                                    onChanged: (value) {
                                      controller.selectedTakingRide.value =
                                          ContactModel(
                                              fullName: "Myself".tr,
                                              contactNumber: "");
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        ListView.builder(
                          itemCount: controller.contactList.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            ContactModel contactModel =
                                controller.contactList[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: InkWell(
                                onTap: () {
                                  controller.selectedTakingRide.value =
                                      contactModel;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    border: Border.all(
                                        color: controller.selectedTakingRide
                                                    .value.fullName ==
                                                contactModel.fullName
                                            ? themeChange.getThem()
                                                ? AppColors.darkModePrimary
                                                : AppColors.primary
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.person,
                                              color: Colors.black),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            contactModel.fullName.toString(),
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                        Radio(
                                          value:
                                              contactModel.fullName.toString(),
                                          groupValue: controller
                                              .selectedTakingRide
                                              .value
                                              .fullName,
                                          activeColor: themeChange.getThem()
                                              ? AppColors.darkModePrimary
                                              : AppColors.primary,
                                          onChanged: (value) {
                                            controller.selectedTakingRide
                                                .value = contactModel;
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              final FlutterNativeContactPicker contactPicker =
                                  FlutterNativeContactPicker();
                              Contact? contact =
                                  await contactPicker.selectContact();
                              ContactModel contactModel = ContactModel();
                              contactModel.fullName = contact!.fullName ?? "";
                              contactModel.contactNumber =
                                  contact.selectedPhoneNumber;

                              if (!controller.contactList
                                  .contains(contactModel)) {
                                controller.contactList.add(contactModel);
                                controller.setContact();
                              }
                            } catch (e) {
                              rethrow;
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child:
                                      Icon(Icons.contacts, color: Colors.black),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    "Choose another contact".tr,
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ButtonThem.buildButton(
                          context,
                          title:
                              "${"Book for ".tr} ${controller.selectedTakingRide.value.fullName}",
                          onPress: () async {
                            Get.back();
                          },
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          });
        });
  }

  ariPortDialog(
      BuildContext context, HomeController controller, bool isSource) {
    return showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        builder: (context1) {
          final themeChange = Provider.of<DarkThemeProvider>(context1);

          return StatefulBuilder(builder: (context1, setState) {
            return Container(
              constraints:
                  BoxConstraints(maxHeight: Responsive.height(90, context)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Do you want to travel for AirPort?",
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Choose a single AirPort",
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ListView.builder(
                        itemCount: Constant.airaPortList!.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          AriPortModel airPortModel =
                              Constant.airaPortList![index];
                          return Obx(
                            () => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: InkWell(
                                onTap: () {
                                  controller.selectedAirPort.value =
                                      airPortModel;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    border: Border.all(
                                        color: controller
                                                    .selectedAirPort.value.id ==
                                                airPortModel.id
                                            ? themeChange.getThem()
                                                ? AppColors.darkModePrimary
                                                : AppColors.primary
                                            : AppColors.textFieldBorder,
                                        width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.airplanemode_active,
                                              color: Colors.black),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            airPortModel.airportName.toString(),
                                            style: GoogleFonts.poppins(),
                                          ),
                                        ),
                                        Radio(
                                          value: airPortModel.id.toString(),
                                          groupValue: controller
                                              .selectedAirPort.value.id,
                                          activeColor: themeChange.getThem()
                                              ? AppColors.darkModePrimary
                                              : AppColors.primary,
                                          onChanged: (value) {
                                            controller.selectedAirPort.value =
                                                airPortModel;
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ButtonThem.buildButton(
                        context,
                        title: "Book",
                        onPress: () async {
                          if (controller.selectedAirPort.value.id != null) {
                            if (isSource) {
                              controller.sourceLocationController.value.text =
                                  controller.selectedAirPort.value.airportName
                                      .toString();
                              controller.sourceLocationLAtLng.value =
                                  LocationLatLng(
                                      latitude: double.parse(controller
                                          .selectedAirPort.value.airportLat
                                          .toString()),
                                      longitude: double.parse(controller
                                          .selectedAirPort.value.airportLng
                                          .toString()));
                              controller.calculateAmount();
                            } else {
                              controller.destinationLocationController.value
                                      .text =
                                  controller.selectedAirPort.value.airportName
                                      .toString();
                              controller.destinationLocationLAtLng.value =
                                  LocationLatLng(
                                      latitude: double.parse(controller
                                          .selectedAirPort.value.airportLat
                                          .toString()),
                                      longitude: double.parse(controller
                                          .selectedAirPort.value.airportLng
                                          .toString()));
                              controller.calculateAmount();
                            }
                            Get.back();
                          } else {
                            ShowToastDialog.showToast(
                                "Please select one airport");
                          }
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {
        Get.back();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Warning".tr),
      content: Text(
          "You are not able book new ride please complete previous ride payment"
              .tr),
      actions: [
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

// warningDailog() {
//   return Dialog(
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), //this right here
//     child: SizedBox(
//       height: 300.0,
//       width: 300.0,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           const Padding(
//             padding: EdgeInsets.all(15.0),
//             child: Text(
//               'Warning!',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.all(15.0),
//             child: Text(
//               'You are not able book new ride please complete previous ride payment',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//           const Padding(padding: EdgeInsets.only(top: 50.0)),
//           TextButton(
//               onPressed: () {
//                 Get.back();
//               },
//               child: const Text(
//                 'Ok',
//                 style: TextStyle(color: Colors.purple, fontSize: 18.0),
//               ))
//         ],
//       ),
//     ),
//   );
// }

  /// Extracted booking logic used by all payment methods
  Future<void> _proceedWithBooking(
      BuildContext context, HomeController controller) async {
    ShowToastDialog.showLoader("Please wait");
    OrderModel orderModel = OrderModel();
    orderModel.id = Constant.getUuid();
    orderModel.userId = FireStoreUtils.getCurrentUid();
    orderModel.sourceLocationName =
        controller.sourceLocationController.value.text;
    orderModel.destinationLocationName =
        controller.destinationLocationController.value.text;
    orderModel.sourceLocationLAtLng = controller.sourceLocationLAtLng.value;
    orderModel.destinationLocationLAtLng =
        controller.destinationLocationLAtLng.value;
    orderModel.distance = controller.distance.value;
    orderModel.acNonAcCharges = '';
    orderModel.duration = controller.duration.value;
    orderModel.distanceType = Constant.distanceType;
    orderModel.offerRate = controller.amount.value;
    orderModel.serviceId = controller.selectedType.value.id;
    orderModel.destinationless = false; // Normal ride with destination
    GeoFirePoint position = Geoflutterfire().point(
        latitude: controller.sourceLocationLAtLng.value.latitude!,
        longitude: controller.sourceLocationLAtLng.value.longitude!);

    orderModel.position =
        Positions(geoPoint: position.geoPoint, geohash: position.hash);
    orderModel.createdDate = Timestamp.now();
    orderModel.status = Constant.ridePlaced;
    orderModel.paymentType = controller.selectedPaymentMethod.value;
    orderModel.paymentStatus = false;
    orderModel.service = controller.selectedType.value;
    orderModel.adminCommission =
        controller.selectedType.value.adminCommission!.isEnabled == false
            ? controller.selectedType.value.adminCommission!
            : Constant.adminCommission;
    orderModel.otp = Constant.getReferralCode();
    orderModel.isAcSelected = controller.selectedType.value.isAcNonAc == true
        ? controller.isAcSelected.value
        : false;
    orderModel.taxList = Constant.taxList;
    if (controller.selectedTakingRide.value.fullName != "Myself") {
      orderModel.someOneElse = controller.selectedTakingRide.value;
    }

    bool zoneFound = false;
    for (int i = 0; i < controller.zoneList.length; i++) {
      if (Constant.isPointInPolygon(
          LatLng(
              double.parse(
                  controller.sourceLocationLAtLng.value.latitude.toString()),
              double.parse(
                  controller.sourceLocationLAtLng.value.longitude.toString())),
          controller.zoneList[i].area!)) {
        zoneFound = true;
        controller.selectedZone.value = controller.zoneList[i];
        orderModel.zoneId = controller.selectedZone.value.id;
        orderModel.zone = controller.selectedZone.value;
        await FireStoreUtils()
            .sendOrderDataFuture(orderModel)
            .then((eventData) async {
          for (var driver in eventData) {
            if (driver.fcmToken != null) {
              Map<String, dynamic> playLoad = <String, dynamic>{
                "type": "city_order",
                "orderId": orderModel.id
              };
              await SendNotification.sendOneNotification(
                  token: driver.fcmToken.toString(),
                  title: 'New Ride Available',
                  titleAr: 'رحلة جديدة متاحة',
                  body: 'A customer has placed a ride near your location.',
                  bodyAr: 'عميل حجز رحلة بالقرب من موقعك.',
                  payload: playLoad,
                  recipientId: driver.id,
                  recipientType: 'driver',
                  dataOnly:
                      true); // data-only: prevents Firebase from auto-showing a duplicate system notification
            }
          }
        });
        await FireStoreUtils.setOrder(orderModel).then((value) {
          ShowToastDialog.showToast("Ride Placed successfully".tr);
          controller.dashboardController.selectedDrawerIndex(2);
          ShowToastDialog.closeLoader();
          controller.isBookingInProgress.value = false;
        }).catchError((e) {
          ShowToastDialog.closeLoader();
          controller.isBookingInProgress.value = false;
          ShowToastDialog.showToast(
              "Something went wrong, please try again".tr);
        });
        break;
      }
    }
    if (!zoneFound) {
      controller.isBookingInProgress.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
        "Services are currently unavailable on the selected location. Please reach out to the administrator for assistance.",
      );
    }
  }

  /// Shows confirmation dialog for metered ride (destinationless)
  void _showMeteredRideDialog(BuildContext context, HomeController controller) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.local_taxi, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              Text("أخبر السائق  بالواجهه".tr,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("إلغاء".tr,
                  style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _proceedWithMeteredBooking(context, controller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("ابدأ الرحلة".tr,
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _meterInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.poppins(fontSize: 13)),
      ],
    );
  }

  /// Metered ride booking - no destination, fare by actual distance & time
  Future<void> _proceedWithMeteredBooking(
      BuildContext context, HomeController controller) async {
    if (controller.isBookingInProgress.value) return;
    controller.isBookingInProgress.value = true;

    // Validate payment method
    if (controller.selectedPaymentMethod.value.isEmpty) {
      controller.isBookingInProgress.value = false;
      ShowToastDialog.showToast("Please select Payment Method".tr);
      return;
    }

    // Validate source location
    if (controller.sourceLocationController.value.text.isEmpty) {
      controller.isBookingInProgress.value = false;
      ShowToastDialog.showToast("Please select source location".tr);
      return;
    }

    // Check payment status
    bool isPaymentNotCompleted = await FireStoreUtils.paymentStatusCheck();
    if (isPaymentNotCompleted) {
      controller.isBookingInProgress.value = false;
      showAlertDialog(context);
      return;
    }

    ShowToastDialog.showLoader("Please wait");

    OrderModel orderModel = OrderModel();
    orderModel.id = Constant.getUuid();
    orderModel.userId = FireStoreUtils.getCurrentUid();
    orderModel.sourceLocationName =
        controller.sourceLocationController.value.text;
    orderModel.destinationLocationName = "رحلة بالعداد"; // Metered ride label
    orderModel.sourceLocationLAtLng = controller.sourceLocationLAtLng.value;
    orderModel.destinationLocationLAtLng = null; // No destination
    orderModel.distance = "0"; // Will be calculated during ride
    orderModel.duration = "0"; // Will be calculated during ride
    orderModel.acNonAcCharges = '';
    orderModel.distanceType = Constant.distanceType;
    orderModel.offerRate = "0"; // No pre-calculated fare
    orderModel.serviceId = controller.selectedType.value.id;
    orderModel.destinationless = true; // 🔑 Key flag for metered ride

    GeoFirePoint position = Geoflutterfire().point(
        latitude: controller.sourceLocationLAtLng.value.latitude!,
        longitude: controller.sourceLocationLAtLng.value.longitude!);

    orderModel.position =
        Positions(geoPoint: position.geoPoint, geohash: position.hash);
    orderModel.createdDate = Timestamp.now();
    orderModel.status = Constant.ridePlaced;
    orderModel.paymentType = controller.selectedPaymentMethod.value;
    orderModel.paymentStatus = false;
    orderModel.service = controller.selectedType.value;
    orderModel.adminCommission =
        controller.selectedType.value.adminCommission!.isEnabled == false
            ? controller.selectedType.value.adminCommission!
            : Constant.adminCommission;
    orderModel.otp = Constant.getReferralCode();
    orderModel.isAcSelected = false;
    orderModel.taxList = Constant.taxList;
    if (controller.selectedTakingRide.value.fullName != "Myself") {
      orderModel.someOneElse = controller.selectedTakingRide.value;
    }

    bool zoneFound = false;
    for (int i = 0; i < controller.zoneList.length; i++) {
      if (Constant.isPointInPolygon(
          LatLng(
              double.parse(
                  controller.sourceLocationLAtLng.value.latitude.toString()),
              double.parse(
                  controller.sourceLocationLAtLng.value.longitude.toString())),
          controller.zoneList[i].area!)) {
        zoneFound = true;
        controller.selectedZone.value = controller.zoneList[i];
        orderModel.zoneId = controller.selectedZone.value.id;
        orderModel.zone = controller.selectedZone.value;
        await FireStoreUtils()
            .sendOrderDataFuture(orderModel)
            .then((eventData) async {
          for (var driver in eventData) {
            if (driver.fcmToken != null) {
              Map<String, dynamic> playLoad = <String, dynamic>{
                "type": "city_order",
                "orderId": orderModel.id
              };
              await SendNotification.sendOneNotification(
                  token: driver.fcmToken.toString(),
                  title: 'Metered Ride Request',
                  titleAr: 'طلب رحلة بالعداد',
                  body: 'A customer nearby needs a metered ride.',
                  bodyAr: 'عميل قريب منك يحتاج رحلة بالعداد.',
                  payload: playLoad,
                  recipientId: driver.id,
                  recipientType: 'driver',
                  dataOnly: true);
            }
          }
        });
        await FireStoreUtils.setOrder(orderModel).then((value) {
          ShowToastDialog.showToast("تم حجز الرحلة بنجاح".tr);
          controller.dashboardController.selectedDrawerIndex(2);
          ShowToastDialog.closeLoader();
          controller.isBookingInProgress.value = false;
        }).catchError((e) {
          ShowToastDialog.closeLoader();
          controller.isBookingInProgress.value = false;
          ShowToastDialog.showToast(
              "Something went wrong, please try again".tr);
        });
        break;
      }
    }
    if (!zoneFound) {
      controller.isBookingInProgress.value = false;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
        "Services are currently unavailable on the selected location. Please reach out to the administrator for assistance.",
      );
    }
  }
}
