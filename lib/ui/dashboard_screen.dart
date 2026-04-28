import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<DashBoardController>(
        init: DashBoardController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppColors.darkBackground
                : AppColors.background,
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppColors.darkBackground
                  : Colors.white,
              title: controller.selectedDrawerIndex.value != 0 &&
                      controller.selectedDrawerIndex.value != 6
                  ? Text(
                      _getAppBarTitle(controller.selectedDrawerIndex.value),
                      style: TextStyle(
                        color:
                            themeChange.getThem() ? Colors.white : Colors.black,
                      ),
                    )
                  : const Text(""),
              leading: Builder(builder: (context) {
                return InkWell(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 10, right: 20, top: 20, bottom: 20),
                    child: SvgPicture.asset('assets/icons/ic_humber.svg',
                        colorFilter: ColorFilter.mode(
                            AppColors.primary, BlendMode.srcIn)),
                  ),
                );
              }),
              actions: [
                controller.selectedDrawerIndex.value == 0
                    ? FutureBuilder<UserModel?>(
                        future: FireStoreUtils.getUserProfile(
                            FireStoreUtils.getCurrentUid()),
                        builder: (context, snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              return Constant.loader();
                            case ConnectionState.done:
                              if (snapshot.hasError) {
                                return Text(snapshot.error.toString());
                              } else {
                                UserModel driverModel = snapshot.data!;
                                return InkWell(
                                  onTap: () {
                                    controller.selectedDrawerIndex(8);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        height: 40,
                                        width: 36,
                                        imageUrl: Constant.safeImageUrl(
                                            driverModel.profilePic),
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Constant.loader(),
                                        errorWidget: (context, url, error) =>
                                            Constant.placeholderWidget(
                                          height: 40,
                                          width: 36,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            default:
                              return Text('Error'.tr);
                          }
                        })
                    : Container(),
              ],
            ),
            drawer: buildAppDrawer(context, controller),
            body: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop) {
                    final now = DateTime.now();
                    if (now.difference(controller.currentBackPressTime.value) >
                        const Duration(seconds: 2)) {
                      controller.currentBackPressTime.value = now;
                      ShowToastDialog.showToast('Double press to exit'.tr);
                    } else {
                      SystemNavigator.pop();
                    }
                  }
                },
                child: controller
                    .getDrawerItemWidget(controller.selectedDrawerIndex.value)),
          );
        });
  }

  String _getAppBarTitle(int index) {
    const keys = [
      'City',
      'OutStation',
      'Rides',
      'OutStation Rides',
      'My Wallet',
      'Settings',
      'Referral a friends',
      'Inbox',
      'Profile',
      'Contact us',
      'FAQs',
      'Log out',
    ];
    if (index >= 0 && index < keys.length) {
      return keys[index].tr;
    }
    return '';
  }

  buildAppDrawer(BuildContext context, DashBoardController controller) {
    RxList<DrawerItem> drawerItems = [
      DrawerItem('City'.tr, "assets/icons/ic_city.svg"),
      DrawerItem('OutStation'.tr, "assets/icons/ic_intercity.svg"),
      DrawerItem('Rides'.tr, "assets/icons/ic_order.svg"),
      DrawerItem('OutStation Rides'.tr, "assets/icons/ic_order.svg"),
      DrawerItem('My Wallet'.tr, "assets/images/logo_bankily.png"),
      DrawerItem('Settings'.tr, "assets/icons/ic_settings.svg"),
      DrawerItem('Referral a friends'.tr, "assets/icons/ic_referral.svg"),
      DrawerItem('Inbox'.tr, "assets/icons/ic_inbox.svg"),
      DrawerItem('Profile'.tr, "assets/icons/ic_profile.svg"),
      DrawerItem('Contact us'.tr, "assets/icons/ic_contact_us.svg"),
      DrawerItem('FAQs'.tr, "assets/icons/ic_faq.svg"),
      DrawerItem('Log out'.tr, "assets/icons/ic_logout.svg"),
    ].obs;
    var drawerOptions = <Widget>[];
    for (var i = 0; i < drawerItems.length; i++) {
      var d = drawerItems[i];
      drawerOptions.add(InkWell(
        onTap: () {
          controller.onSelectItem(i);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
                color: i == controller.selectedDrawerIndex.value
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: const BorderRadius.all(Radius.circular(10))),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                d.icon.endsWith('.svg')
                    ? SvgPicture.asset(
                        d.icon,
                        width: 20,
                        color: i == controller.selectedDrawerIndex.value
                            ? Colors.white
                            : AppColors.drawerIcon,
                      )
                    : Image.asset(
                        d.icon,
                        width: 20,
                        height: 20,
                      ),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  d.title,
                  style: GoogleFonts.poppins(
                      color: i == controller.selectedDrawerIndex.value
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
        ),
      ));
    }
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        children: [
          DrawerHeader(
            child: FutureBuilder<UserModel?>(
                future: FireStoreUtils.getUserProfile(
                    FireStoreUtils.getCurrentUid()),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return Constant.loader();
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      } else {
                        UserModel driverModel = snapshot.data!;
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(56),
                                child: CachedNetworkImage(
                                  height: Responsive.width(18, context),
                                  width: Responsive.width(18, context),
                                  imageUrl: Constant.safeImageUrl(
                                      driverModel.profilePic),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Constant.loader(),
                                  errorWidget: (context, url, error) =>
                                      Constant.placeholderWidget(
                                    height: Responsive.width(20, context),
                                    width: Responsive.width(20, context),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    driverModel.fullName.toString(),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    driverModel.email.toString(),
                                    style: GoogleFonts.poppins(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }
                    default:
                      return Text('Error'.tr);
                  }
                }),
          ),
          Column(children: drawerOptions),
        ],
      ),
    );
  }
}
