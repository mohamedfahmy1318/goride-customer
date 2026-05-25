import 'package:cloud_firestore/cloud_firestore.dart';

class Positions {
  String? geohash;
  GeoPoint? geoPoint;
  // When the driver app last wrote this position. The dispatch fan-out
  // (customer + Cloud Functions + AdminRideService) filters drivers whose
  // updatedAt is older than `positionStaleAfterMinutes`. Optional for
  // backward-compat with legacy docs.
  Timestamp? updatedAt;

  Positions({this.geohash, this.geoPoint, this.updatedAt});

  Positions.fromJson(Map<String, dynamic> json) {
    geohash = json['geohash'];
    geoPoint = json['geopoint'];
    final raw = json['updatedAt'];
    if (raw is Timestamp) {
      updatedAt = raw;
    } else {
      updatedAt = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['geohash'] = geohash;
    data['geopoint'] = geoPoint;
    if (updatedAt != null) {
      data['updatedAt'] = updatedAt;
    }
    return data;
  }
}
