import 'dart:io';

import 'package:bottom_picker/bottom_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/interCity_controller.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/intercity_service_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InterCityScreen extends StatelessWidget {
  const InterCityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<InterCityController>(
      init: InterCityController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.getThem()
              ? AppColors.darkBackground
              : AppColors.background,
          body: controller.isLoading.value
              ? Constant.loader()
              : Column(
                  children: [
                    SizedBox(
                      height: Responsive.width(4, context),
                      width: Responsive.width(100, context),
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
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  InkWell(
                                      onTap: () async {
                                        final result = await Get.to(
                                          () => Constant.selectedMapType == 'osm'
                                              ? const OsmMapPickerPage()
                                              : const GoogleMapSearchPlacesApi(),
                                          transition: Transition.rightToLeft,
                                        );
                                        if (result is PlaceDetailsModel &&
                                            result.result?.geometry?.location?.lat != null &&
                                            result.result?.geometry?.location?.lng != null) {
                                          final addr = result.result!.formattedAddress?.toString() ?? '';
                                          controller.sourceCityController.value.text = addr;
                                          controller.sourceLocationController.value.text = addr;
                                          controller.sourceLocationLAtLng.value = LocationLatLng(
                                            latitude: result.result!.geometry!.location!.lat,
                                            longitude: result.result!.geometry!.location!.lng,
                                          );
                                          Constant.selectedMapType == 'osm'
                                              ? controller.calculateOsmAmount()
                                              : controller.calculateAmount();
                                        }
                                      },
                                      child: TextFieldThem.buildTextFiled(
                                        context,
                                        hintText: 'From'.tr,
                                        controller: controller
                                            .sourceLocationController.value,
                                        enable: false,
                                      )),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  InkWell(
                                      onTap: () async {
                                        final result = await Get.to(
                                          () => Constant.selectedMapType == 'osm'
                                              ? const OsmMapPickerPage()
                                              : const GoogleMapSearchPlacesApi(),
                                          transition: Transition.rightToLeft,
                                        );
                                        if (result is PlaceDetailsModel &&
                                            result.result?.geometry?.location?.lat != null &&
                                            result.result?.geometry?.location?.lng != null) {
                                          final addr = result.result!.formattedAddress?.toString() ?? '';
                                          controller.destinationCityController.value.text = addr;
                                          controller.destinationLocationController.value.text = addr;
                                          controller.destinationLocationLAtLng.value = LocationLatLng(
                                            latitude: result.result!.geometry!.location!.lat,
                                            longitude: result.result!.geometry!.location!.lng,
                                          );
                                          Constant.selectedMapType == 'osm'
                                              ? controller.calculateOsmAmount()
                                              : controller.calculateAmount();
                                        }
                                      },
                                      child: TextFieldThem.buildTextFiled(
                                        context,
                                        hintText: 'To'.tr,
                                        controller: controller
                                            .destinationLocationController
                                            .value,
                                        enable: false,
                                      )),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text("Select Option".tr,
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
                                          controller.intercityService.length,
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemBuilder: (context, index) {
                                        IntercityServiceModel serviceModel =
                                            controller.intercityService[index];
                                        return Obx(
                                          () => InkWell(
                                            onTap: () {
                                              controller.selectedInterCityType
                                                  .value = serviceModel;
                                              if (Constant.selectedMapType ==
                                                  'osm') {
                                                controller.calculateOsmAmount();
                                              } else {
                                                controller.calculateAmount();
                                              }
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              child: Container(
                                                width: Responsive.width(
                                                    28, context),
                                                decoration: BoxDecoration(
                                                    color: controller
                                                                .selectedInterCityType
                                                                .value ==
                                                            serviceModel
                                                        ? themeChange.getThem()
                                                            ? AppColors
                                                                .darkModePrimary
                                                            : AppColors.primary
                                                        : themeChange.getThem()
                                                            ? AppColors
                                                                .darkService
                                                            : controller.colors[
                                                                index %
                                                                    controller
                                                                        .colors
                                                                        .length],
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(20),
                                                    )),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      decoration: BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .surface,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(
                                                            Radius.circular(20),
                                                          )),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: Constant
                                                              .safeImageUrl(
                                                                  serviceModel
                                                                      .image),
                                                          fit: BoxFit.contain,
                                                          height:
                                                              Responsive.height(
                                                                  8, context),
                                                          width:
                                                              Responsive.width(
                                                                  18, context),
                                                          placeholder: (context,
                                                                  url) =>
                                                              Constant.loader(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              const Icon(
                                                                  Icons
                                                                      .directions_car,
                                                                  size: 40,
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text(
                                                        Constant
                                                            .localizationName(
                                                                serviceModel
                                                                    .name),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                color: controller
                                                                            .selectedInterCityType
                                                                            .value ==
                                                                        serviceModel
                                                                    ? themeChange
                                                                            .getThem()
                                                                        ? Colors
                                                                            .black
                                                                        : Colors
                                                                            .white
                                                                    : themeChange
                                                                            .getThem()
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  InkWell(
                                      onTap: () async {
                                        BottomPicker.dateTime(
                                          onSubmit: (index) {
                                            controller.dateAndTime = index;
                                            DateFormat dateFormat = DateFormat(
                                                "EEE dd MMMM , HH:mm aa");
                                            String string =
                                                dateFormat.format(index);

                                            controller.whenController.value
                                                .text = string;
                                          },
                                          minDateTime: DateTime.now(),
                                          buttonAlignment:
                                              MainAxisAlignment.center,
                                          displaySubmitButton: true,
                                          pickerTitle: const Text(''),
                                          buttonSingleColor: AppColors.primary,
                                        ).show(context);
                                      },
                                      child: TextFieldThem.buildTextFiled(
                                        context,
                                        hintText: 'When'.tr,
                                        controller:
                                            controller.whenController.value,
                                        enable: false,
                                      )),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  controller.selectedInterCityType.value.id ==
                                          "647f350983ba2"
                                      ? Column(
                                          children: [
                                            TextFieldThem.buildTextFiled(
                                              context,
                                              hintText:
                                                  'Parcel weight (In Kg.)'.tr,
                                              controller:
                                                  controller.parcelWeight.value,
                                              keyBoardType:
                                                  TextInputType.number,
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            TextFieldThem.buildTextFiled(
                                              context,
                                              hintText:
                                                  'Parcel dimension(In ft.)'.tr,
                                              controller: controller
                                                  .parcelDimension.value,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(r'[0-9*]')),
                                              ], // Only numbers can be entered
                                            ),
                                            parcelImageWidget(
                                                context, controller),
                                          ],
                                        )
                                      : TextFieldThem.buildTextFiled(
                                          context,
                                          hintText: 'Number of Passengers'.tr,
                                          controller:
                                              controller.noOfPassengers.value,
                                          keyBoardType: TextInputType.number,
                                        ),
                                  Obx(
                                    () => controller.sourceLocationLAtLng.value
                                                    .latitude !=
                                                null &&
                                            controller.destinationLocationLAtLng
                                                    .value.latitude !=
                                                null
                                        ? Column(
                                            children: [
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                          color: AppColors.gray,
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          10))),
                                                  child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 10),
                                                      child: Center(
                                                        child: RichText(
                                                          text: TextSpan(
                                                              text:
                                                                  '${"Recommended Price".tr} ${Constant.amountShow(amount: controller.amount.value)}. ${"Approx time".tr} ${controller.duration}',
                                                              style: GoogleFonts.poppins(color: Colors.black),
                                                              children: [
                                                                TextSpan(
                                                                    text: '',
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                            color:
                                                                                Colors.black))
                                                              ]),
                                                        ),
                                                      )),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                            ],
                                          )
                                        : Container(),
                                  ),
                                  Visibility(
                                    visible: false,
                                    child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: TextFieldThem
                                            .buildTextFiledWithPrefixIcon(
                                          context,
                                          hintText: "Enter your offer rate".tr,
                                          inputFormatters: <TextInputFormatter>[
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'[0-9*]')),
                                          ],
                                          controller: controller
                                              .offerYourRateController.value,
                                          prefix: Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10),
                                            child: Text(Constant
                                                .currencyModel!.symbol
                                                .toString()),
                                          ),
                                        )),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  TextFieldThem.buildTextFiled(
                                    context,
                                    hintText: 'Comments'.tr,
                                    controller:
                                        controller.commentsController.value,
                                    keyBoardType: TextInputType.text,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  ButtonThem.buildButton(
                                    context,
                                    title: controller.selectedInterCityType
                                                .value.id ==
                                            "647f350983ba2"
                                        ? "Order Parcel"
                                        : "Ride Placed".tr,
                                    btnWidthRatio:
                                        Responsive.width(100, context),
                                    onPress: () async {
                                      bool isPaymentNotCompleted =
                                          await FireStoreUtils
                                              .paymentStatusCheckIntercity();

                                      if (isPaymentNotCompleted) {
                                        showAlertDialog(context);
                                      } else {
                                        if (controller.sourceLocationLAtLng
                                                    .value.latitude !=
                                                null &&
                                            controller.destinationLocationLAtLng
                                                    .value.latitude !=
                                                null) {
                                          for (int i = 0;
                                              i < controller.zoneList.length;
                                              i++) {
                                            if (Constant.isPointInPolygon(
                                              LatLng(
                                                  double.parse(controller
                                                      .sourceLocationLAtLng
                                                      .value
                                                      .latitude
                                                      .toString()),
                                                  double.parse(controller
                                                      .sourceLocationLAtLng
                                                      .value
                                                      .longitude
                                                      .toString())),
                                              controller.zoneList[i].area!,
                                            )) {
                                              controller.selectedZone.value =
                                                  controller.zoneList[i];
                                              if (controller
                                                      .selectedInterCityType
                                                      .value
                                                      .id ==
                                                  "647f350983ba2") {
                                                if (controller
                                                    .sourceLocationController
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please select source location"
                                                          .tr);
                                                } else if (controller
                                                    .destinationLocationController
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please select destination location"
                                                          .tr);
                                                } else if (controller
                                                    .parcelWeight
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please enter parcel weight"
                                                          .tr);
                                                } else if (controller
                                                    .parcelDimension
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please enter parcel dimension"
                                                          .tr);
                                                } else if (controller
                                                    .whenController
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please select date and time"
                                                          .tr);
                                                } else {
                                                  ShowToastDialog.showLoader(
                                                      "Please wait".tr);

                                                  List<dynamic> parcelImages =
                                                      [];
                                                  for (var element
                                                      in controller.images) {
                                                    Url url = await Constant()
                                                        .uploadChatImageToFireStorage(
                                                            File(element.path));
                                                    parcelImages.add(url.url);
                                                  }

                                                  InterCityOrderModel
                                                      intercityOrderModel =
                                                      InterCityOrderModel();
                                                  intercityOrderModel.id =
                                                      Constant.getUuid();
                                                  intercityOrderModel.userId =
                                                      FireStoreUtils
                                                          .getCurrentUid();
                                                  intercityOrderModel
                                                          .sourceLocationName =
                                                      controller
                                                          .sourceLocationController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .sourceCity =
                                                      controller
                                                          .sourceCityController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .sourceLocationLAtLng =
                                                      controller
                                                          .sourceLocationLAtLng
                                                          .value;

                                                  intercityOrderModel
                                                          .parcelImage =
                                                      parcelImages;
                                                  intercityOrderModel
                                                          .parcelWeight =
                                                      controller.parcelWeight
                                                          .value.text;
                                                  intercityOrderModel
                                                          .parcelDimension =
                                                      controller.parcelDimension
                                                          .value.text;

                                                  intercityOrderModel
                                                          .destinationLocationName =
                                                      controller
                                                          .destinationLocationController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .destinationCity =
                                                      controller
                                                          .destinationCityController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .destinationLocationLAtLng =
                                                      controller
                                                          .destinationLocationLAtLng
                                                          .value;
                                                  intercityOrderModel.distance =
                                                      controller.distance.value;
                                                  intercityOrderModel
                                                          .offerRate =
                                                      controller.amount.value;
                                                  intercityOrderModel
                                                          .intercityServiceId =
                                                      controller
                                                          .selectedInterCityType
                                                          .value
                                                          .id;
                                                  intercityOrderModel
                                                          .intercityService =
                                                      controller
                                                          .selectedInterCityType
                                                          .value;
                                                  GeoFirePoint position =
                                                      Geoflutterfire().point(
                                                          latitude: controller
                                                              .sourceLocationLAtLng
                                                              .value
                                                              .latitude!,
                                                          longitude: controller
                                                              .sourceLocationLAtLng
                                                              .value
                                                              .longitude!);

                                                  intercityOrderModel.position =
                                                      Positions(
                                                          geoPoint:
                                                              position.geoPoint,
                                                          geohash:
                                                              position.hash);
                                                  intercityOrderModel
                                                          .createdDate =
                                                      Timestamp.now();
                                                  intercityOrderModel.status =
                                                      Constant.ridePlaced;
                                                  // paymentType is read by the
                                                  // driver app, Cloud Functions
                                                  // and the dashboard, so the
                                                  // field stays — pinned to
                                                  // "Cash" (cash-only
                                                  // deployment).
                                                  intercityOrderModel
                                                      .paymentType = "Cash";
                                                  intercityOrderModel
                                                      .paymentStatus = false;
                                                  intercityOrderModel.whenTime =
                                                      DateFormat("HH:mm")
                                                          .format(controller
                                                              .dateAndTime!);
                                                  intercityOrderModel
                                                          .whenDates =
                                                      DateFormat("dd-MMM-yyyy")
                                                          .format(controller
                                                              .dateAndTime!);
                                                  intercityOrderModel.comments =
                                                      controller
                                                          .commentsController
                                                          .value
                                                          .text;
                                                  intercityOrderModel.otp =
                                                      Constant
                                                          .getReferralCode();
                                                  intercityOrderModel.taxList =
                                                      Constant.taxList;
                                                  intercityOrderModel.zoneId =
                                                      controller.selectedZone
                                                          .value.id;
                                                  intercityOrderModel.zone =
                                                      controller
                                                          .selectedZone.value;
                                                  intercityOrderModel
                                                      .adminCommission = controller
                                                              .selectedInterCityType
                                                              .value
                                                              .adminCommission!
                                                              .isEnabled ==
                                                          false
                                                      ? controller
                                                          .selectedInterCityType
                                                          .value
                                                          .adminCommission!
                                                      : Constant
                                                          .adminCommission;
                                                  intercityOrderModel
                                                          .distanceType =
                                                      Constant.distanceType;
                                                  await FireStoreUtils
                                                          .setInterCityOrder(
                                                              intercityOrderModel)
                                                      .then((value) async {
                                                    ShowToastDialog
                                                        .closeLoader();
                                                    if (value == true) {
                                                      ShowToastDialog.showToast(
                                                          "Ride Placed successfully"
                                                              .tr);
                                                      _notifyDriversForIntercityOrder(
                                                          intercityOrderModel);
                                                      controller
                                                          .dashboardController
                                                          .selectedDrawerIndex(
                                                              3);
                                                    }
                                                  });
                                                }
                                              } else {
                                                if (controller
                                                    .sourceLocationController
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please select source location"
                                                          .tr);
                                                } else if (controller
                                                    .destinationLocationController
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please select destination location"
                                                          .tr);
                                                } else if (controller
                                                    .noOfPassengers
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please enter Number of passenger"
                                                          .tr);
                                                } else if (controller
                                                    .whenController
                                                    .value
                                                    .text
                                                    .isEmpty) {
                                                  ShowToastDialog.showToast(
                                                      "Please select date and time"
                                                          .tr);
                                                } else {
                                                  ShowToastDialog.showLoader(
                                                      "Please wait".tr);
                                                  InterCityOrderModel
                                                      intercityOrderModel =
                                                      InterCityOrderModel();
                                                  intercityOrderModel.id =
                                                      Constant.getUuid();
                                                  intercityOrderModel.userId =
                                                      FireStoreUtils
                                                          .getCurrentUid();
                                                  intercityOrderModel
                                                          .sourceLocationName =
                                                      controller
                                                          .sourceLocationController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .sourceCity =
                                                      controller
                                                          .sourceCityController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .sourceLocationLAtLng =
                                                      controller
                                                          .sourceLocationLAtLng
                                                          .value;

                                                  intercityOrderModel
                                                          .destinationLocationName =
                                                      controller
                                                          .destinationLocationController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .destinationCity =
                                                      controller
                                                          .destinationCityController
                                                          .value
                                                          .text;
                                                  intercityOrderModel
                                                          .destinationLocationLAtLng =
                                                      controller
                                                          .destinationLocationLAtLng
                                                          .value;
                                                  intercityOrderModel.distance =
                                                      controller.distance.value;
                                                  intercityOrderModel
                                                          .offerRate =
                                                      controller.amount.value;
                                                  intercityOrderModel
                                                          .intercityServiceId =
                                                      controller
                                                          .selectedInterCityType
                                                          .value
                                                          .id;
                                                  intercityOrderModel
                                                          .intercityService =
                                                      controller
                                                          .selectedInterCityType
                                                          .value;
                                                  GeoFirePoint position =
                                                      Geoflutterfire().point(
                                                          latitude: controller
                                                              .sourceLocationLAtLng
                                                              .value
                                                              .latitude!,
                                                          longitude: controller
                                                              .sourceLocationLAtLng
                                                              .value
                                                              .longitude!);

                                                  intercityOrderModel.position =
                                                      Positions(
                                                          geoPoint:
                                                              position.geoPoint,
                                                          geohash:
                                                              position.hash);
                                                  intercityOrderModel
                                                          .createdDate =
                                                      Timestamp.now();
                                                  intercityOrderModel.status =
                                                      Constant.ridePlaced;
                                                  // paymentType is read by the
                                                  // driver app, Cloud Functions
                                                  // and the dashboard, so the
                                                  // field stays — pinned to
                                                  // "Cash" (cash-only
                                                  // deployment).
                                                  intercityOrderModel
                                                      .paymentType = "Cash";
                                                  intercityOrderModel
                                                      .paymentStatus = false;
                                                  intercityOrderModel.whenTime =
                                                      DateFormat("HH:mm")
                                                          .format(controller
                                                              .dateAndTime!);
                                                  intercityOrderModel
                                                          .whenDates =
                                                      DateFormat("dd-MMM-yyyy")
                                                          .format(controller
                                                              .dateAndTime!);
                                                  intercityOrderModel
                                                          .numberOfPassenger =
                                                      controller.noOfPassengers
                                                          .value.text;
                                                  intercityOrderModel.comments =
                                                      controller
                                                          .commentsController
                                                          .value
                                                          .text;
                                                  intercityOrderModel.otp =
                                                      Constant
                                                          .getReferralCode();
                                                  intercityOrderModel.taxList =
                                                      Constant.taxList;
                                                  intercityOrderModel
                                                      .adminCommission = controller
                                                              .selectedInterCityType
                                                              .value
                                                              .adminCommission!
                                                              .isEnabled ==
                                                          false
                                                      ? controller
                                                          .selectedInterCityType
                                                          .value
                                                          .adminCommission!
                                                      : Constant
                                                          .adminCommission;
                                                  intercityOrderModel
                                                          .distanceType =
                                                      Constant.distanceType;
                                                  intercityOrderModel.zoneId =
                                                      controller.selectedZone
                                                          .value.id;
                                                  intercityOrderModel.zone =
                                                      controller
                                                          .selectedZone.value;
                                                  await FireStoreUtils
                                                          .setInterCityOrder(
                                                              intercityOrderModel)
                                                      .then((value) async {
                                                    ShowToastDialog
                                                        .closeLoader();
                                                    if (value == true) {
                                                      ShowToastDialog.showToast(
                                                          "Ride Placed successfully"
                                                              .tr);
                                                      _notifyDriversForIntercityOrder(
                                                          intercityOrderModel);
                                                      controller
                                                          .dashboardController
                                                          .selectedDrawerIndex(
                                                              3);
                                                    }
                                                  });
                                                }
                                              }
                                              break;
                                            } else {
                                              ShowToastDialog.showToast(
                                                "Services are currently unavailable on the selected location. Please reach out to the administrator for assistance.",
                                              );
                                            }
                                          }
                                        } else {
                                          ShowToastDialog.showToast(
                                              "Please select location");
                                        }
                                      }
                                    },
                                  ),
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
      },
    );
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr),
      onPressed: () {
        Get.back();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Warning".tr),
      content: Text(
          "You are not able to book a new ride. Please complete your previous ride payment."
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

  parcelImageWidget(BuildContext context, InterCityController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15),
      child: SizedBox(
        height: 100,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Obx(
                () => ListView.builder(
                  itemCount: controller.images.length,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        width: 100,
                        height: 100.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: FileImage(
                                  File(controller.images[index].path))),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8.0)),
                        ),
                        child: InkWell(
                            onTap: () {
                              controller.images.removeAt(index);
                            },
                            child: const Icon(
                              Icons.remove_circle,
                              size: 30,
                            )),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () {
                    _onCameraClick(context, controller);
                  },
                  child: Image.asset(
                    'assets/images/parcel_add_image.png',
                    height: 100,
                    width: 100,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _onCameraClick(BuildContext context, InterCityController controller) {
    final action = CupertinoActionSheet(
      message: Text(
        'Add your parcel image.'.tr,
        style: const TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            await ImagePicker().pickMultiImage().then((value) {
              for (var element in value) {
                controller.images.add(element);
              }
            });
          },
          child: Text('Choose image from gallery'.tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Get.back();
            final XFile? photo =
                await ImagePicker().pickImage(source: ImageSource.camera);
            if (photo != null) {
              controller.images.add(photo);
            }
          },
          child: Text('Take a picture'.tr),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          'Cancel'.tr,
        ),
        onPressed: () {
          Get.back();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}

/// Sends FCM data-only push to all online drivers in the order's zone.
/// Fire-and-forget — does not block the booking flow.
void _notifyDriversForIntercityOrder(InterCityOrderModel orderModel) async {
  if (orderModel.zoneId == null || orderModel.zoneId!.isEmpty) return;
  try {
    List drivers =
        await FireStoreUtils.getDriversInZoneForIntercity(orderModel.zoneId!);

    // Compute the same fare breakdown the city_order Cloud Functions path
    // produces via computeFareBreakdown — keeps driver-side UX consistent
    // across city and intercity dispatch, even when the callable's silent
    // enrichment catch fires.
    final double intercityTotalFare =
        double.tryParse(orderModel.offerRate ?? '0') ?? 0;
    double intercityCommission = 0;
    final intercityCfg = orderModel.adminCommission;
    if (intercityCfg != null && intercityCfg.isEnabled == true) {
      final double cfgAmount =
          double.tryParse(intercityCfg.amount?.toString() ?? '0') ?? 0;
      intercityCommission = intercityCfg.type == 'fix'
          ? cfgAmount
          : (intercityTotalFare * cfgAmount) / 100;
    }
    final double intercityEarnings =
        (intercityTotalFare - intercityCommission)
            .clamp(0, double.infinity)
            .toDouble();

    for (var driver in drivers) {
      if (driver.fcmToken != null && driver.fcmToken!.isNotEmpty) {
        Map<String, dynamic> payload = {
          "type": "intercity_order",
          "orderId": orderModel.id,
          "total_fare": intercityTotalFare.toStringAsFixed(2),
          "admin_commission": intercityCommission.toStringAsFixed(2),
          "driver_earnings": intercityEarnings.toStringAsFixed(2),
          "trip_distance": orderModel.distance ?? '',
        };
        await SendNotification.sendOneNotification(
          token: driver.fcmToken!,
          title: 'Intercity Ride Request',
          titleAr: 'طلب رحلة بين المدن',
          body:
              'A customer needs a ride from ${orderModel.sourceLocationName ?? orderModel.sourceCity} to ${orderModel.destinationLocationName ?? orderModel.destinationCity}',
          bodyAr:
              'عميل يحتاج رحلة من ${orderModel.sourceLocationName ?? orderModel.sourceCity} إلى ${orderModel.destinationLocationName ?? orderModel.destinationCity}',
          payload: payload,
          recipientId: driver.id,
          recipientType: 'driver',
          dataOnly: true,
        );
      }
    }
  } catch (e) {
    // Non-critical — order is already saved, don't block on notification failure
  }
}
