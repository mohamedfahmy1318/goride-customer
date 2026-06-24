import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/home_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_them.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:customer/model/place_picker_model.dart';
import 'package:customer/widget/google_map_search_place.dart';
import 'package:customer/widget/osm_map_picker_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.userModel.value.fullName.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: themeChange.getThem()
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  letterSpacing: 1,
                                ),
                              ),
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
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      controller.currentLocation.value,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: themeChange.getThem()
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
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
                                                          final result =
                                                              await Get.to(
                                                            () => Constant
                                                                        .selectedMapType ==
                                                                    'osm'
                                                                ? const OsmMapPickerPage()
                                                                : const GoogleMapSearchPlacesApi(),
                                                            transition:
                                                                Transition
                                                                    .rightToLeft,
                                                          );
                                                          if (result
                                                                  is PlaceDetailsModel &&
                                                              result
                                                                      .result
                                                                      ?.geometry
                                                                      ?.location
                                                                      ?.lat !=
                                                                  null &&
                                                              result
                                                                      .result
                                                                      ?.geometry
                                                                      ?.location
                                                                      ?.lng !=
                                                                  null) {
                                                            controller
                                                                .destinationLocationController
                                                                .value
                                                                .text = result
                                                                    .result!
                                                                    .formattedAddress
                                                                    ?.toString() ??
                                                                '';
                                                            controller
                                                                    .destinationLocationLAtLng
                                                                    .value =
                                                                LocationLatLng(
                                                              latitude: result
                                                                  .result!
                                                                  .geometry!
                                                                  .location!
                                                                  .lat,
                                                              longitude: result
                                                                  .result!
                                                                  .geometry!
                                                                  .location!
                                                                  .lng,
                                                            );
                                                            await controller
                                                                .calculateDurationAndDistance();
                                                            controller
                                                                .calculateAmount();
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
                                                    "Tell driver".tr,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Start ride without destination"
                                                        .tr,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
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
                                                                    .surface,
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
                                    _buildPromoCodeRow(context, controller),
                                    const SizedBox(height: 10),
                                    _buildFareBreakdown(context, controller),
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
                                        if (controller
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
                                        } else {
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

  ariPortDialog(
      BuildContext context, HomeController controller, bool isSource) {
    return showModalBottomSheet(
        backgroundColor: Theme.of(context).colorScheme.surface,
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

  /// Promo-code input row: text field + Apply / Remove button. Shown in the
  /// booking sheet between the payment picker and the "Book Ride" button.
  /// Auto-uppercases input and clears internal state via HomeController.
  Widget _buildPromoCodeRow(BuildContext context, HomeController controller) {
    return Obx(() {
      final applied = controller.appliedCoupon.value;
      final busy = controller.isApplyingCoupon.value;
      return Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          border: Border.all(color: AppColors.textFieldBorder, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.local_offer_outlined, size: 22, color: Colors.grey[700]),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller.promoCodeController,
                enabled: applied == null && !busy,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: applied != null
                      ? "${"Applied".tr}: ${applied.code ?? ''}"
                      : "Enter promo code".tr,
                  hintStyle: GoogleFonts.poppins(
                    color: applied != null
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.greenAccent
                            : Colors.green[700])
                        : Colors.grey[500],
                    fontWeight:
                        applied != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (applied != null)
              TextButton(
                onPressed: controller.clearPromoCode,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  "Remove".tr,
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  controller
                      .applyPromoCode(controller.promoCodeController.text);
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  "Apply".tr,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Compact price breakdown shown beneath the promo row when a fare has
  /// been calculated. Hidden for zero/invalid subtotals (e.g. before the
  /// customer picks a destination) and skips the discount line when no
  /// coupon is applied.
  Widget _buildFareBreakdown(BuildContext context, HomeController controller) {
    return Obx(() {
      final double subTotal = double.tryParse(controller.amount.value) ?? 0;
      if (subTotal <= 0) return const SizedBox.shrink();
      final double discount = controller.discountAmount.value;
      final double payable = controller.finalPayable;
      final bool hasDiscount = discount > 0;
      if (!hasDiscount) return const SizedBox.shrink();

      TextStyle labelStyle() => GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[700],
          );
      TextStyle valueStyle({bool bold = false, Color? color}) =>
          GoogleFonts.poppins(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? Colors.black87,
          );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text("Subtotal".tr, style: labelStyle())),
                Text(
                  Constant.amountShow(amount: subTotal.toStringAsFixed(2)),
                  style: valueStyle(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                    child: Text("Discount Applied".tr,
                        style:
                            labelStyle().copyWith(color: Colors.green[700]))),
                Text(
                  "- ${Constant.amountShow(amount: discount.toStringAsFixed(2))}",
                  style: valueStyle(color: Colors.green[700]),
                ),
              ],
            ),
            const Divider(height: 14),
            Row(
              children: [
                Expanded(
                    child: Text("Total Payable".tr,
                        style: labelStyle().copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700))),
                Text(
                  Constant.amountShow(amount: payable.toStringAsFixed(2)),
                  style: valueStyle(bold: true, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

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
    // paymentType is read by the driver app, Cloud Functions and the
    // dashboard, so the field stays — pinned to "Cash" (cash-only deployment;
    // matches settings/payment.cash.name and every reader's fallback).
    orderModel.paymentType = "Cash";
    orderModel.paymentStatus = false;
    orderModel.service = controller.selectedType.value;
    orderModel.adminCommission =
        controller.selectedType.value.adminCommission!.isEnabled == false
            ? controller.selectedType.value.adminCommission!
            : Constant.adminCommission;

    final double computedTotalFare =
        double.tryParse(orderModel.offerRate ?? '0') ?? 0;
    // NOTE: do NOT gate this on `isEnabled` — on a per-service config that
    // flag means "use the GLOBAL commission" (dashboard semantics), so it is
    // false exactly when the service's own rate applies. Gating on it
    // persisted adminCommissionAmount="0.00" for per-service rates and the
    // settlement CF then fell back to completion-time computation (the
    // "9% configured but ~6% deducted" bug). The helper itself returns 0 for
    // a null/empty config, which covers commission-disabled deployments.
    final double computedCommission = Constant.calculateOrderAdminCommission(
      amount: orderModel.offerRate,
      adminCommission: orderModel.adminCommission,
    );
    final double computedDriverEarnings =
        (computedTotalFare - computedCommission).clamp(0, double.infinity);
    orderModel.totalFare = computedTotalFare.toStringAsFixed(2);
    orderModel.adminCommissionAmount = computedCommission.toStringAsFixed(2);
    orderModel.driverEarnings = computedDriverEarnings.toStringAsFixed(2);

    // Company-absorbs coupon model: the discount reduces what the customer
    // pays but does NOT touch adminCommissionAmount or driverEarnings above
    // — those stay pegged to the gross totalFare so the driver's take is
    // unaffected by promos. The platform's net commission capture shrinks
    // instead (adminCommission − discount).
    final appliedCoupon = controller.appliedCoupon.value;
    final double discount = (appliedCoupon != null &&
            controller.discountAmount.value > 0 &&
            orderModel.destinationless != true)
        ? Constant.calculateCouponDiscount(
            subTotal: computedTotalFare,
            coupon: appliedCoupon,
          )
        : 0.0;
    final double finalPayable =
        (computedTotalFare - discount).clamp(0, double.infinity).toDouble();
    orderModel.discountAmount = discount.toStringAsFixed(2);
    orderModel.finalPayableAmount = finalPayable.toStringAsFixed(2);
    if (appliedCoupon != null && discount > 0) {
      orderModel.coupon = appliedCoupon;
    }

    orderModel.otp = Constant.getReferralCode();
    orderModel.isAcSelected = controller.selectedType.value.isAcNonAc == true
        ? controller.isAcSelected.value
        : false;
    orderModel.taxList = Constant.taxList;

    ZoneModel? matchedZone;
    for (int i = 0; i < controller.zoneList.length; i++) {
      if (Constant.isPointInPolygon(
          LatLng(
              double.parse(
                  controller.sourceLocationLAtLng.value.latitude.toString()),
              double.parse(
                  controller.sourceLocationLAtLng.value.longitude.toString())),
          controller.zoneList[i].area!)) {
        matchedZone = controller.zoneList[i];
        break;
      }
    }

    // Out-of-zone pickups (outside every published service-zone polygon) are
    // allowed so the platform operates everywhere: the ride still dispatches, to
    // the nearest online driver at any distance (the 3 km cap applies only inside
    // a zone). Zoned pickups keep their zone (per-zone dispatch config preserved).
    if (matchedZone != null) {
      controller.selectedZone.value = matchedZone;
      orderModel.zoneId = matchedZone.id;
      orderModel.zone = matchedZone;
    } else {
      orderModel.zoneId = '';
      orderModel.zone = null;
    }
    orderModel.dispatchMode = 'smart_escalation';
    orderModel.notifiedDriverIds = [];
    await FireStoreUtils.setOrder(orderModel).then((value) {
      ShowToastDialog.showToast("Ride Placed successfully".tr);
      controller.dashboardController.selectedDrawerIndex(2);
      ShowToastDialog.closeLoader();
      controller.isBookingInProgress.value = false;
      // Coupon was redeemed atomically inside setOrder's transaction.
      // Reset local state so the next booking starts without a stale promo.
      controller.clearPromoCode();
    }).catchError((e) {
      ShowToastDialog.closeLoader();
      controller.isBookingInProgress.value = false;
      ShowToastDialog.showToast("Something went wrong, please try again".tr);
    });
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
              Text("Tell driver".tr,
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
    orderModel.destinationLocationName = "رحلة مفتوح"; // Metered ride label
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
    // paymentType is read by the driver app, Cloud Functions and the
    // dashboard, so the field stays — pinned to "Cash" (cash-only deployment;
    // matches settings/payment.cash.name and every reader's fallback).
    orderModel.paymentType = "Cash";
    orderModel.paymentStatus = false;
    orderModel.service = controller.selectedType.value;
    orderModel.adminCommission =
        controller.selectedType.value.adminCommission!.isEnabled == false
            ? controller.selectedType.value.adminCommission!
            : Constant.adminCommission;

    final double computedTotalFare =
        double.tryParse(orderModel.offerRate ?? '0') ?? 0;
    // NOTE: do NOT gate this on `isEnabled` — on a per-service config that
    // flag means "use the GLOBAL commission" (dashboard semantics), so it is
    // false exactly when the service's own rate applies. Gating on it
    // persisted adminCommissionAmount="0.00" for per-service rates and the
    // settlement CF then fell back to completion-time computation (the
    // "9% configured but ~6% deducted" bug). The helper itself returns 0 for
    // a null/empty config, which covers commission-disabled deployments.
    final double computedCommission = Constant.calculateOrderAdminCommission(
      amount: orderModel.offerRate,
      adminCommission: orderModel.adminCommission,
    );
    final double computedDriverEarnings =
        (computedTotalFare - computedCommission).clamp(0, double.infinity);
    orderModel.totalFare = computedTotalFare.toStringAsFixed(2);
    orderModel.adminCommissionAmount = computedCommission.toStringAsFixed(2);
    orderModel.driverEarnings = computedDriverEarnings.toStringAsFixed(2);

    // Company-absorbs coupon model: the discount reduces what the customer
    // pays but does NOT touch adminCommissionAmount or driverEarnings above
    // — those stay pegged to the gross totalFare so the driver's take is
    // unaffected by promos. The platform's net commission capture shrinks
    // instead (adminCommission − discount).
    final appliedCoupon = controller.appliedCoupon.value;
    final double discount = (appliedCoupon != null &&
            controller.discountAmount.value > 0 &&
            orderModel.destinationless != true)
        ? Constant.calculateCouponDiscount(
            subTotal: computedTotalFare,
            coupon: appliedCoupon,
          )
        : 0.0;
    final double finalPayable =
        (computedTotalFare - discount).clamp(0, double.infinity).toDouble();
    orderModel.discountAmount = discount.toStringAsFixed(2);
    orderModel.finalPayableAmount = finalPayable.toStringAsFixed(2);
    if (appliedCoupon != null && discount > 0) {
      orderModel.coupon = appliedCoupon;
    }

    orderModel.otp = Constant.getReferralCode();
    orderModel.isAcSelected = false;
    orderModel.taxList = Constant.taxList;

    ZoneModel? matchedZone;
    for (int i = 0; i < controller.zoneList.length; i++) {
      if (Constant.isPointInPolygon(
          LatLng(
              double.parse(
                  controller.sourceLocationLAtLng.value.latitude.toString()),
              double.parse(
                  controller.sourceLocationLAtLng.value.longitude.toString())),
          controller.zoneList[i].area!)) {
        matchedZone = controller.zoneList[i];
        break;
      }
    }

    // Out-of-zone pickups are allowed (operate everywhere): the ride still
    // dispatches, to the nearest online driver at any distance. Zoned pickups
    // keep their zone. Mirrors the non-metered booking path above.
    if (matchedZone != null) {
      controller.selectedZone.value = matchedZone;
      orderModel.zoneId = matchedZone.id;
      orderModel.zone = matchedZone;
    } else {
      orderModel.zoneId = '';
      orderModel.zone = null;
    }
    orderModel.dispatchMode = 'smart_escalation';
    orderModel.notifiedDriverIds = [];
    await FireStoreUtils.setOrder(orderModel).then((value) {
      ShowToastDialog.showToast("تم حجز الرحلة بنجاح".tr);
      controller.dashboardController.selectedDrawerIndex(2);
      ShowToastDialog.closeLoader();
      controller.isBookingInProgress.value = false;
    }).catchError((e) {
      ShowToastDialog.closeLoader();
      controller.isBookingInProgress.value = false;
      ShowToastDialog.showToast("Something went wrong, please try again".tr);
    });
  }
}
