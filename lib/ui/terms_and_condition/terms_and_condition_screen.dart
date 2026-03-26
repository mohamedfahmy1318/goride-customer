import 'package:customer/constant/constant.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class TermsAndConditionScreen extends StatelessWidget {
  final String? type;
  const TermsAndConditionScreen({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.getThem()
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            themeChange.getThem() ? AppColors.darkBackground : Colors.white,
        title: Text(
            type == "privacy" ? "Privacy Policy".tr : "Terms and Conditions".tr,
            style: TextStyle(
                color: themeChange.getThem() ? Colors.white : Colors.black)),
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
            height: Responsive.width(8, context),
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SingleChildScrollView(
                    child: Html(
                      shrinkWrap: true,
                      data: type == "privacy"
                          ? Constant.localizationPrivacyPolicy(
                              Constant.privacyPolicy)
                          : Constant.localizationTermsCondition(
                              Constant.termsAndConditions),
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
