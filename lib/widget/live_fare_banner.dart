import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/DarkThemeProvider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Live fare banner for the customer's view of a رحلة بالعداد.
///
/// Subscribes to the ride doc and renders the running [finalRate] /
/// [actualDistance] / [actualDuration] that the driver app writes every
/// few seconds. Parent should only mount this when the ride is metered.
class LiveFareBanner extends StatelessWidget {
  const LiveFareBanner({
    super.key,
    required this.orderId,
    this.compact = false,
  });

  final String orderId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FireStoreUtils.fireStore
          .collection(CollectionName.orders)
          .doc(orderId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !(snap.data?.exists ?? false)) {
          return const SizedBox.shrink();
        }
        final data = snap.data!.data() ?? const <String, dynamic>{};
        // The status field guard is also enforced by the parent, but a second
        // check here keeps the banner from briefly showing stale fields if the
        // ride flips out of InProgress while the widget is still mounted.
        if (data['status'] != Constant.rideInProgress ||
            data['destinationless'] != true) {
          return const SizedBox.shrink();
        }
        final double fare =
            double.tryParse(data['finalRate']?.toString() ?? '') ?? 0.0;
        final double distance =
            double.tryParse(data['actualDistance']?.toString() ?? '') ?? 0.0;
        final double duration =
            double.tryParse(data['actualDuration']?.toString() ?? '') ?? 0.0;

        return Container(
          margin: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 10, vertical: compact ? 4 : 8),
          padding: EdgeInsets.symmetric(
              horizontal: 14, vertical: compact ? 10 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: themeChange.getThem()
                  ? [const Color(0xff2E7D32), const Color(0xff1B5E20)]
                  : [AppColors.primary, const Color(0xff5BC100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _PulseDot(),
              const SizedBox(width: 8),
              Text(
                "Meter Ride - Live".tr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 13,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Constant.amountShow(amount: fare.toStringAsFixed(2)),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 18 : 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${distance.toStringAsFixed(2)} km · ${duration.toStringAsFixed(0)} min",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w500,
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
