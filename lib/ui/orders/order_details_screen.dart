import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controller/order_details_controller.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/ui/orders/live_tracking_screen.dart';
import 'package:customer/widget/location_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetBuilder<OrderDetailsController>(
        init: OrderDetailsController(),
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
                      color:
                          themeChange.getThem() ? Colors.white : Colors.black)),
              leading: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: themeChange.getThem() ? Colors.white : Colors.black,
                  )),
            ),
            body: Column(
              children: [
                SizedBox(
                  height: Responsive.width(6, context),
                  width: Responsive.width(100, context),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: themeChange.getThem()
                            ? AppColors.darkGray
                            : AppColors.gray,
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25))),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: StreamBuilder(
                        stream: FireStoreUtils.fireStore
                            .collection(CollectionName.orders)
                            .doc(controller.orderModel.value.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Something went wrong'.tr));
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Constant.loader();
                          }

                          final Map<String, dynamic> orderRaw =
                              _asMap(snapshot.data!.data());

                          OrderModel orderModel = OrderModel.fromJson(orderRaw);

                          final Map<String, dynamic> smartDispatch =
                              _asMap(orderRaw['smartDispatch']);
                          final Map<String, dynamic> dispatchConfig =
                              _asMap(orderRaw['dispatchConfig']);

                          final String stageKey =
                              (orderRaw['dispatchStageKey'] ??
                                      smartDispatch['stageKey'] ??
                                      'smart_dispatch_stage_matching')
                                  .toString();

                          final int stageIndex = _resolveStageIndex(stageKey);
                          final int dispatchedWaves = _toInt(
                              smartDispatch['wave'] ??
                                  orderRaw['dispatchWave']);
                          final int dispatchAttempts = _toInt(
                              smartDispatch['attempt'] ??
                                  orderRaw['dispatchAttempt']);
                          final int totalWaves = _toInt(
                              smartDispatch['totalWaves'] ??
                                  dispatchConfig['totalWaves']);
                          final int notifiedDrivers = _toInt(
                              smartDispatch['notifiedDrivers'] ??
                                  dispatchConfig['notifiedDrivers']);
                          final int timeoutSeconds = _toInt(
                              smartDispatch['timeoutSeconds'] ??
                                  dispatchConfig['timeoutSeconds']);

                          int remainingSeconds = 0;
                          if (timeoutSeconds > 0 &&
                              orderModel.createdDate != null) {
                            final int elapsedSeconds =
                                ((DateTime.now().millisecondsSinceEpoch -
                                            orderModel.createdDate!
                                                .millisecondsSinceEpoch) /
                                        1000)
                                    .floor();
                            remainingSeconds = (timeoutSeconds - elapsedSeconds)
                                .clamp(0, timeoutSeconds);
                          }

                          // If ride was cancelled, go back
                          if (orderModel.status == Constant.rideCanceled) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Get.back();
                            });
                            return const SizedBox.shrink();
                          }

                          // If a driver has been assigned, navigate to live tracking
                          if (orderModel.status != Constant.ridePlaced) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Get.off(
                                const LiveTrackingScreen(),
                                arguments: {
                                  "orderModel": orderModel,
                                  "type": "orderModel",
                                },
                              );
                            });
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 60),
                                  const SizedBox(height: 16),
                                  Text("Driver assigned!".tr,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18)),
                                ],
                              ),
                            );
                          }

                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          orderModel.status.toString().tr,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        Constant.amountShow(
                                            amount: orderModel
                                                .customerPayableFareText),
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LocationView(
                                    sourceLocation: orderModel
                                        .sourceLocationName
                                        .toString(),
                                    destinationLocation: orderModel
                                        .destinationLocationName
                                        .toString(),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    decoration: BoxDecoration(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBorder
                                            : Colors.white,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10))),
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 14),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text("Ride Details".tr,
                                                  style: GoogleFonts.poppins()),
                                            ),
                                            Text(
                                                Constant().formatTimestamp(
                                                    orderModel.createdDate),
                                                style: GoogleFonts.poppins()),
                                          ],
                                        )),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: themeChange.getThem()
                                          ? AppColors.darkContainerBorder
                                          : Colors.white,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(12)),
                                      border: Border.all(
                                        color: themeChange.getThem()
                                            ? AppColors.darkContainerBackground
                                            : AppColors.containerBorder,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Dispatch Progress".tr,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        _buildDispatchStep(
                                          title:
                                              'smart_dispatch_stage_matching_title'
                                                  .tr,
                                          subtitle:
                                              'smart_dispatch_stage_matching_subtitle'
                                                  .tr,
                                          isCompleted: stageIndex > 0,
                                          isActive: stageIndex == 0,
                                          darkMode: themeChange.getThem(),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildDispatchStep(
                                          title:
                                              'smart_dispatch_stage_expanding_title'
                                                  .tr,
                                          subtitle:
                                              'smart_dispatch_stage_expanding_subtitle'
                                                  .tr,
                                          isCompleted: stageIndex > 1,
                                          isActive: stageIndex == 1,
                                          darkMode: themeChange.getThem(),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildDispatchStep(
                                          title:
                                              'smart_dispatch_stage_final_title'
                                                  .tr,
                                          subtitle:
                                              'smart_dispatch_stage_final_subtitle'
                                                  .tr,
                                          isCompleted: stageIndex > 2,
                                          isActive: stageIndex == 2,
                                          darkMode: themeChange.getThem(),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 8,
                                          children: [
                                            Text(
                                              '${"Dispatch wave".tr}: ${dispatchedWaves > 0 ? dispatchedWaves : dispatchAttempts}${totalWaves > 0 ? '/$totalWaves' : ''}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[700]),
                                            ),
                                            Text(
                                              '${"Drivers notified".tr}: $notifiedDrivers',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[700]),
                                            ),
                                            if (timeoutSeconds > 0)
                                              Text(
                                                '${"Time left".tr}: ${remainingSeconds}s',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[700]),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Waiting for driver animation
                                  Center(
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: CircularProgressIndicator(),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "Searching for a driver...".tr,
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Please wait, a driver will be assigned automatically"
                                              .tr,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13, color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ButtonThem.buildButton(
                                    context,
                                    title: "Cancel".tr,
                                    btnHeight: 44,
                                    onPress: () async {
                                      orderModel.status = Constant.rideCanceled;
                                      orderModel.acceptedDriverId = [];
                                      await FireStoreUtils.setOrder(orderModel)
                                          .then((value) {
                                        Get.back();
                                      });
                                    },
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  int _resolveStageIndex(String stageKey) {
    switch (stageKey) {
      case 'smart_dispatch_stage_expanding':
        return 1;
      case 'smart_dispatch_stage_final':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildDispatchStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool darkMode,
  }) {
    final Color indicatorColor = isCompleted || isActive
        ? AppColors.primary
        : (darkMode ? AppColors.darkContainerBackground : Colors.grey.shade300);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          height: 18,
          width: 18,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
