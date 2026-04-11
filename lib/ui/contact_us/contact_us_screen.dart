import 'package:customer/constant/constant.dart';
import 'package:customer/controller/contact_us_controller.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<ContactUsController>(
        init: ContactUsController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem()
                ? AppColors.darkBackground
                : AppColors.background,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: controller.isLoading.value
                          ? Constant.loader()
                          : Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Contact us".tr,
                                        style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600)),
                                    Text("Let us know your issue & feedback".tr,
                                        style: GoogleFonts.poppins()),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Constant.makePhoneCall('+22222245004');
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.call, size: 28),
                                          const SizedBox(width: 20),
                                          Text('+22222245004',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () async {
                                        final Uri url = Uri.parse(
                                            'https://wa.me/22222245004');
                                        if (!await launchUrl(url,
                                            mode: LaunchMode
                                                .externalApplication)) {
                                          throw Exception(
                                              'Could not launch WhatsApp');
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.chat,
                                              size: 28,
                                              color: Color(0xFF25D366)),
                                          const SizedBox(width: 20),
                                          Text('WhatsApp'.tr,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 28),
                                        const SizedBox(width: 20),
                                        Expanded(
                                            child: Text(
                                                controller.address.value,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 16)))
                                      ],
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
        });
  }
}
