import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/login_controller.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/button_them.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/ui/auth_screen/information_screen.dart';
import 'package:customer/ui/dashboard_screen.dart';
import 'package:customer/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Selector Button
                  SafeArea(
                    bottom: false,
                    child: Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(top: 8, right: 12, left: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => _showLanguageBottomSheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_language.svg',
                                    width: 20,
                                    height: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getCurrentLanguageLabel(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.darkModePrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down,
                                      color: AppColors.primary, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Image.asset("assets/images/login_image.png",
                      width: Responsive.width(100, context)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text("Login".tr,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 18)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                              "Welcome Back! We are happy to have \n you back"
                                  .tr,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w400)),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                            validator: (value) =>
                                value != null && value.isNotEmpty
                                    ? null
                                    : 'Required',
                            keyboardType: TextInputType.number,
                            textCapitalization: TextCapitalization.sentences,
                            controller: controller.phoneNumberController.value,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                                color: themeChange.getThem()
                                    ? Colors.white
                                    : Colors.black),
                            decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: themeChange.getThem()
                                    ? AppColors.darkTextField
                                    : AppColors.textField,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                prefixIcon: CountryCodePicker(
                                  onChanged: (value) {
                                    controller.countryCode.value =
                                        value.dialCode.toString();
                                  },
                                  dialogBackgroundColor: themeChange.getThem()
                                      ? AppColors.darkBackground
                                      : AppColors.background,
                                  initialSelection:
                                      controller.countryCode.value,
                                  comparator: (a, b) =>
                                      b.name!.compareTo(a.name.toString()),
                                  flagDecoration: const BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(2)),
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(4)),
                                  borderSide: BorderSide(
                                      color: themeChange.getThem()
                                          ? AppColors.darkTextFieldBorder
                                          : AppColors.textFieldBorder,
                                      width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(4)),
                                  borderSide: BorderSide(
                                      color: themeChange.getThem()
                                          ? AppColors.primary
                                          : AppColors.primary,
                                      width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(4)),
                                  borderSide: BorderSide(
                                      color: themeChange.getThem()
                                          ? AppColors.primary
                                          : AppColors.primary,
                                      width: 1),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(4)),
                                  borderSide: BorderSide(
                                      color: themeChange.getThem()
                                          ? AppColors.darkTextFieldBorder
                                          : AppColors.textFieldBorder,
                                      width: 1),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(4)),
                                  borderSide: BorderSide(
                                      color: themeChange.getThem()
                                          ? AppColors.darkTextFieldBorder
                                          : AppColors.textFieldBorder,
                                      width: 1),
                                ),
                                hintText: "Phone number".tr)),
                        const SizedBox(
                          height: 30,
                        ),
                        ButtonThem.buildButton(
                          context,
                          title: "Next".tr,
                          onPress: () {
                            controller.sendCode();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 40),
                          child: Row(
                            children: [
                              const Expanded(
                                  child: Divider(
                                height: 1,
                              )),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "OR".tr,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(
                                height: 1,
                              )),
                            ],
                          ),
                        ),
                        ButtonThem.buildBorderButton(
                          context,
                          title: "Login with google".tr,
                          iconVisibility: true,
                          iconAssetImage: 'assets/icons/ic_google.png',
                          onPress: () async {
                            ShowToastDialog.showLoader("Please wait".tr);
                            await controller.signInWithGoogle().then((value) {
                              ShowToastDialog.closeLoader();
                              if (value != null) {
                                if (value.additionalUserInfo!.isNewUser) {
                                  log("----->new user");
                                  UserModel userModel = UserModel();
                                  userModel.id = value.user!.uid;
                                  userModel.email = value.user!.email;
                                  userModel.fullName = value.user!.displayName;
                                  userModel.profilePic = value.user!.photoURL;
                                  userModel.loginType =
                                      Constant.googleLoginType;

                                  ShowToastDialog.closeLoader();
                                  Get.to(const InformationScreen(), arguments: {
                                    "userModel": userModel,
                                  });
                                } else {
                                  log("----->old user");
                                  FireStoreUtils.userExitOrNot(value.user!.uid)
                                      .then((userExit) async {
                                    ShowToastDialog.closeLoader();
                                    if (userExit == true) {
                                      UserModel? userModel =
                                          await FireStoreUtils.getUserProfile(
                                              value.user!.uid);
                                      if (userModel != null) {
                                        if (userModel.isActive == true) {
                                          String token =
                                              await NotificationService
                                                  .getToken();
                                          userModel.fcmToken = token;
                                          await FireStoreUtils.updateUser(
                                              userModel);
                                          Get.offAll(const DashBoardScreen());
                                        } else {
                                          await FirebaseAuth.instance.signOut();
                                          ShowToastDialog.showToast(
                                              "This user is disable please contact administrator"
                                                  .tr);
                                        }
                                      }
                                    } else {
                                      UserModel userModel = UserModel();
                                      userModel.id = value.user!.uid;
                                      userModel.email = value.user!.email;
                                      userModel.fullName =
                                          value.user!.displayName;
                                      userModel.profilePic =
                                          value.user!.photoURL;
                                      userModel.loginType =
                                          Constant.googleLoginType;

                                      Get.to(const InformationScreen(),
                                          arguments: {
                                            "userModel": userModel,
                                          });
                                    }
                                  });
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Visibility(
                            visible: Platform.isIOS,
                            child: ButtonThem.buildBorderButton(
                              context,
                              title: "Login with apple".tr,
                              iconVisibility: true,
                              iconAssetImage: 'assets/icons/ic_apple.png',
                              iconColor: themeChange.getThem()
                                  ? AppColors.darkModePrimary
                                  : Colors.black,
                              onPress: () async {
                                ShowToastDialog.showLoader("Please wait".tr);
                                await controller
                                    .signInWithApple()
                                    .then((value) {
                                  ShowToastDialog.closeLoader();

                                  if (value != null) {
                                    Map<String, dynamic> map = value;
                                    AuthorizationCredentialAppleID
                                        appleCredential =
                                        map['appleCredential'];
                                    UserCredential userCredential =
                                        map['userCredential'];

                                    if (userCredential
                                        .additionalUserInfo!.isNewUser) {
                                      UserModel userModel = UserModel();
                                      userModel.id = userCredential.user!.uid;
                                      userModel.profilePic =
                                          userCredential.user!.photoURL;
                                      userModel.loginType =
                                          Constant.appleLoginType;
                                      userModel.email = userCredential
                                          .additionalUserInfo!
                                          .profile!['email'];
                                      userModel.fullName =
                                          "${appleCredential.givenName} ${appleCredential.familyName}";

                                      ShowToastDialog.closeLoader();
                                      Get.to(const InformationScreen(),
                                          arguments: {
                                            "userModel": userModel,
                                          });
                                    } else {
                                      FireStoreUtils.userExitOrNot(
                                              userCredential.user!.uid)
                                          .then((userExit) async {
                                        ShowToastDialog.closeLoader();

                                        if (userExit == true) {
                                          UserModel? userModel =
                                              await FireStoreUtils
                                                  .getUserProfile(
                                                      userCredential.user!.uid);
                                          if (userModel != null) {
                                            if (userModel.isActive == true) {
                                              Get.offAll(
                                                  const DashBoardScreen());
                                            } else {
                                              await FirebaseAuth.instance
                                                  .signOut();
                                              ShowToastDialog.showToast(
                                                  "This user is disable please contact administrator"
                                                      .tr);
                                            }
                                          }
                                        } else {
                                          UserModel userModel = UserModel();
                                          userModel.id =
                                              userCredential.user!.uid;
                                          userModel.profilePic =
                                              userCredential.user!.photoURL;
                                          userModel.loginType =
                                              Constant.appleLoginType;
                                          userModel.email = userCredential
                                              .additionalUserInfo!
                                              .profile!['email'];
                                          userModel.fullName =
                                              "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}";

                                          Get.to(const InformationScreen(),
                                              arguments: {
                                                "userModel": userModel,
                                              });
                                        }
                                      });
                                    }
                                  }
                                });
                              },
                            )),
                      ],
                    ),
                  )
                ],
              ),
            ),
            bottomNavigationBar: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    text: 'By tapping "Next" you agree to '.tr,
                    style: GoogleFonts.poppins(),
                    children: <TextSpan>[
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "terms",
                              ));
                            },
                          text: 'Terms and conditions'.tr,
                          style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline)),
                      TextSpan(text: 'and'.tr, style: GoogleFonts.poppins()),
                      TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.to(const TermsAndConditionScreen(
                                type: "privacy",
                              ));
                            },
                          text: 'privacy policy'.tr,
                          style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline)),
                      // can add more TextSpans here...
                    ],
                  ),
                )),
          );
        });
  }

  String _getCurrentLanguageLabel() {
    final locale = Get.locale?.languageCode ?? 'en';
    switch (locale) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final currentLocale = Get.locale?.languageCode ?? 'en';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Language".tr,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageTile(
                context: context,
                flag: '🇬🇧',
                label: 'English',
                code: 'en',
                isSelected: currentLocale == 'en',
              ),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                label: 'العربية',
                code: 'ar',
                isSelected: currentLocale == 'ar',
              ),
              _buildLanguageTile(
                context: context,
                flag: '🇫🇷',
                label: 'Français',
                code: 'fr',
                isSelected: currentLocale == 'fr',
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String flag,
    required String label,
    required String code,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _changeLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String langCode) async {
    // Build a LanguageModel-like JSON to match what settings screen saves
    final langData = {
      'code': langCode,
      'name': langCode == 'ar'
          ? 'العربية'
          : (langCode == 'fr' ? 'Français' : 'English'),
      'isRtl': langCode == 'ar',
      'isDefault': false,
      'enable': true,
      'id': langCode,
    };
    Preferences.setString(Preferences.languageCodeKey, jsonEncode(langData));
    Get.back(); // Close bottom sheet
    await Get.updateLocale(Locale(langCode));
  }
}
