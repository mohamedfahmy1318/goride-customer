import 'dart:convert';

import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/services/localization_service.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controller/setting_controller.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<SettingController>(
        init: SettingController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppColors.darkBackground
                : AppColors.background,
            body: controller.isLoading.value
                ? Constant.loader()
                : Column(
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
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(25),
                                  topRight: Radius.circular(25))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                                'assets/icons/ic_language.svg',
                                                width: 24),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            Expanded(
                                              child: Text(
                                                "Language".tr,
                                                style: GoogleFonts.poppins(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                            SizedBox(
                                              width:
                                                  Responsive.width(26, context),
                                              child: DropdownButtonFormField(
                                                  isExpanded: true,
                                                  decoration:
                                                      const InputDecoration(
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 1),
                                                    disabledBorder:
                                                        InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                  ),
                                                  initialValue: controller
                                                              .selectedLanguage
                                                              .value
                                                              .id ==
                                                          null
                                                      ? null
                                                      : controller
                                                          .selectedLanguage
                                                          .value,
                                                  onChanged: (value) {
                                                    controller.selectedLanguage
                                                        .value = value!;

                                                    LocalizationService()
                                                        .changeLocale(value.code
                                                            .toString());
                                                    Preferences.setString(
                                                        Preferences
                                                            .languageCodeKey,
                                                        jsonEncode(controller
                                                            .selectedLanguage
                                                            .value));
                                                    // Save language to Firestore
                                                    FireStoreUtils
                                                        .updateUserLanguage(
                                                            value.code
                                                                .toString());
                                                  },
                                                  hint: Text("select".tr),
                                                  items: controller.languageList
                                                      .map((item) {
                                                    return DropdownMenuItem(
                                                      value: item,
                                                      child: Text(
                                                          item.name.toString(),
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500)),
                                                    );
                                                  }).toList()),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          onTap: () async {
                                            final Uri url = Uri.parse(
                                                'https://wa.me/966542883129');
                                            if (!await launchUrl(url,
                                                mode: LaunchMode
                                                    .externalApplication)) {
                                              throw Exception(
                                                  'Could not launch WhatsApp'
                                                      .tr);
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                  'assets/icons/ic_support.svg',
                                                  width: 24),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              Text("Support".tr,
                                                  style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: InkWell(
                                          onTap: () {
                                            showAlertDialog(context);
                                          },
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                  'assets/icons/ic_delete.svg',
                                                  width: 24),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              Text("Delete Account".tr,
                                                  style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w500))
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child:
                                      Text("${'V'.tr} ${Constant.appVersion}"),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        });
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK".tr),
      onPressed: () async {
        Get.back();
        final String rawSupport = Constant.supportURL ?? '';
        final String supportLink =
            rawSupport.isNotEmpty ? rawSupport : 'https://wa.me/966542883129';
        final Uri url = Uri.parse(supportLink);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          ShowToastDialog.showToast("Please contact to administrator".tr);
        }
      },
    );
    Widget cancel = TextButton(
      child: Text("Cancel".tr),
      onPressed: () {
        Get.back();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Account delete".tr),
      content: Text("Are you sure want to delete Account.".tr),
      actions: [
        okButton,
        cancel,
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
}
