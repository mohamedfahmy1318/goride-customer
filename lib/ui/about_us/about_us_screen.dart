import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  bool isLoading = true;
  String phone = '';
  String email = '';
  String address = '';
  String description = '';
  String supportURL = '';
  String facebookUrl = '';
  String instagramUrl = '';
  String twitterUrl = '';
  String whatsappNumber = '';
  String tiktokUrl = '';
  String snapchatUrl = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection(CollectionName.settings)
        .doc('contact_us')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        phone = data['phone'] ?? '';
        email = data['email'] ?? '';
        address = data['address'] ?? '';
        description = data['companyDescription'] ?? '';
        supportURL = data['supportURL'] ?? '';
        facebookUrl = data['facebookUrl'] ?? '';
        instagramUrl = data['instagramUrl'] ?? '';
        twitterUrl = data['twitterUrl'] ?? '';
        whatsappNumber = data['whatsappNumber'] ?? '';
        tiktokUrl = data['tiktokUrl'] ?? '';
        snapchatUrl = data['snapchatUrl'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(
            height: Responsive.width(10, context),
            width: Responsive.width(100, context),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: isLoading
                  ? Constant.loader()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/new_icon_app.png',
                              width: 100,
                              height: 100,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.directions_car,
                                    color: Colors.white, size: 50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'GO RIDE',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 30),

                          // Contact Info
                          if (phone.isNotEmpty)
                            _buildInfoTile(
                              icon: Icons.phone,
                              title: 'Phone'.tr,
                              value: phone,
                              onTap: () => Constant.makePhoneCall(phone),
                              isDark: isDark,
                            ),
                          if (email.isNotEmpty)
                            _buildInfoTile(
                              icon: Icons.email,
                              title: 'Email'.tr,
                              value: email,
                              onTap: () => _launchUrl('mailto:$email'),
                              isDark: isDark,
                            ),
                          if (address.isNotEmpty)
                            _buildInfoTile(
                              icon: Icons.location_on,
                              title: 'Address'.tr,
                              value: address,
                              isDark: isDark,
                            ),
                          if (supportURL.isNotEmpty)
                            _buildInfoTile(
                              icon: Icons.language,
                              title: 'Website'.tr,
                              value: supportURL,
                              onTap: () => _launchUrl(supportURL),
                              isDark: isDark,
                            ),

                          // Social Media
                          if (_hasSocialMedia()) ...[
                            const SizedBox(height: 30),
                            Text(
                              'Follow Us'.tr,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                if (facebookUrl.isNotEmpty)
                                  _buildSocialButton(
                                    icon: Icons.facebook,
                                    label: 'Facebook',
                                    color: const Color(0xFF1877F2),
                                    onTap: () => _launchUrl(facebookUrl),
                                  ),
                                if (instagramUrl.isNotEmpty)
                                  _buildSocialButton(
                                    icon: Icons.camera_alt,
                                    label: 'Instagram',
                                    color: const Color(0xFFE4405F),
                                    onTap: () => _launchUrl(instagramUrl),
                                  ),
                                if (twitterUrl.isNotEmpty)
                                  _buildSocialButton(
                                    icon: Icons.alternate_email,
                                    label: 'X',
                                    color: Colors.black,
                                    onTap: () => _launchUrl(twitterUrl),
                                  ),
                                if (whatsappNumber.isNotEmpty)
                                  _buildSocialButton(
                                    icon: Icons.chat,
                                    label: 'WhatsApp',
                                    color: const Color(0xFF25D366),
                                    onTap: () => _launchUrl(
                                        'https://wa.me/${whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '')}'),
                                  ),
                                if (tiktokUrl.isNotEmpty)
                                  _buildSocialButton(
                                    icon: Icons.music_note,
                                    label: 'TikTok',
                                    color: Colors.black,
                                    onTap: () => _launchUrl(tiktokUrl),
                                  ),
                                if (snapchatUrl.isNotEmpty)
                                  _buildSocialButton(
                                    icon: Icons.photo_camera_front,
                                    label: 'Snapchat',
                                    color: const Color(0xFFFFFC00),
                                    onTap: () => _launchUrl(snapchatUrl),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSocialMedia() {
    return facebookUrl.isNotEmpty ||
        instagramUrl.isNotEmpty ||
        twitterUrl.isNotEmpty ||
        whatsappNumber.isNotEmpty ||
        tiktokUrl.isNotEmpty ||
        snapchatUrl.isNotEmpty;
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkTextField : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkTextFieldBorder : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color == const Color(0xFFFFFC00) ? Colors.black : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
