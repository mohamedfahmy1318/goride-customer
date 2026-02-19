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

                          OrderModel orderModel =
                              OrderModel.fromJson(snapshot.data!.data()!);

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
                                            amount: orderModel.offerRate
                                                .toString()),
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
}
