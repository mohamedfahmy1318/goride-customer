import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/faq_model.dart';
import 'package:customer/model/inbox_model.dart';
import 'package:customer/model/intercity_order_model.dart';
import 'package:customer/model/intercity_service_model.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/model/language_privacy_policy.dart';
import 'package:customer/model/language_terms_condition.dart';
import 'package:customer/model/on_boarding_model.dart';
import 'package:customer/model/order/driverId_accept_reject.dart';
import 'package:customer/model/order_model.dart';
import 'package:customer/model/payment_model.dart';
import 'package:customer/model/referral_model.dart';
import 'package:customer/model/review_model.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/sos_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/wallet_transaction_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/widget/geoflutterfire/src/geoflutterfire.dart';
import 'package:customer/widget/geoflutterfire/src/models/point.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FireStoreUtils {
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static Future<bool> isLogin() async {
    bool isLogin = false;
    if (FirebaseAuth.instance.currentUser != null) {
      isLogin = await userExitOrNot(FirebaseAuth.instance.currentUser!.uid);
    } else {
      isLogin = false;
    }
    return isLogin;
  }

  getSettings() async {
    await fireStore
        .collection(CollectionName.settings)
        .doc("globalKey")
        .get()
        .then((value) {
      if (value.exists) {
        String key = value.data()!["googleMapKey"] ?? '';
        if (key.isNotEmpty) {
          Constant.mapAPIKey = key;
          log('✅ Google Map API Key loaded from Firestore');
        } else {
          // Fallback: use the key from AndroidManifest.xml
          Constant.mapAPIKey = 'AIzaSyAb3p2UEDZuLOPokFUTwpHEkpORrayXig0';
          log('⚠️ googleMapKey is empty in Firestore, using fallback key');
        }
      } else {
        Constant.mapAPIKey = 'AIzaSyAb3p2UEDZuLOPokFUTwpHEkpORrayXig0';
        log('⚠️ settings/globalKey document does not exist, using fallback key');
      }
    }).catchError((e) {
      Constant.mapAPIKey = 'AIzaSyAb3p2UEDZuLOPokFUTwpHEkpORrayXig0';
      log('❌ Error loading globalKey: $e, using fallback key');
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("notification_setting")
        .get()
        .then((value) {
      if (value.exists) {
        if (value.data() != null) {
          Constant.senderId = value.data()!['senderId'].toString();
          Constant.jsonNotificationFileURL =
              value.data()!['serviceJson'].toString();
        }
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("globalValue")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.distanceType = value.data()!["distanceType"].toString().trim();
        Constant.radius = value.data()!["radius"].toString().trim();
        Constant.mapType = value.data()!["mapType"].toString().trim();
        Constant.selectedMapType =
            value.data()!["selectedMapType"].toString().trim();
        Constant.driverLocationUpdate =
            value.data()!["driverLocationUpdate"].toString().trim();
        Constant.regionCode = value.data()!["regionCode"].toString().trim();
        Constant.regionCountry =
            value.data()!["regionCountry"].toString().trim();
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("global")
        .get()
        .then((value) {
      if (value.exists) {
        if (value.data()!["privacyPolicy"] != null) {
          Constant.privacyPolicy = <LanguagePrivacyPolicy>[];
          value.data()!["privacyPolicy"].forEach((v) {
            Constant.privacyPolicy.add(LanguagePrivacyPolicy.fromJson(v));
          });
        }

        if (value.data()!["termsAndConditions"] != null) {
          Constant.termsAndConditions = <LanguageTermsCondition>[];
          value.data()!["termsAndConditions"].forEach((v) {
            Constant.termsAndConditions.add(LanguageTermsCondition.fromJson(v));
          });
        }

        Constant.appVersion = value.data()!["appVersion"];
      }
    });

    fireStore
        .collection(CollectionName.settings)
        .doc("adminCommission")
        .snapshots()
        .listen((value) {
      if (value.data() != null) {
        AdminCommission adminCommission =
            AdminCommission.fromJson(value.data()!);
        if (adminCommission.isEnabled == true) {
          Constant.adminCommission = adminCommission;
        }
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("referral")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.referralAmount = value.data()!["referralAmount"];
      }
    });

    await fireStore
        .collection(CollectionName.settings)
        .doc("contact_us")
        .get()
        .then((value) {
      if (value.exists) {
        Constant.supportURL = value.data()!["supportURL"];
      }
    });
  }

  static String getCurrentUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  static Future updateReferralAmount(OrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        try {
          final referralUserId = referralModel!.referralBy!;
          final userDocRef =
              fireStore.collection(CollectionName.users).doc(referralUserId);
          await fireStore.runTransaction((transaction) async {
            final snapshot = await transaction.get(userDocRef);
            if (!snapshot.exists || snapshot.data() == null) return;
            final currentWallet = double.parse(
                (snapshot.data()!['walletAmount'] ?? '0').toString());
            final newWallet = currentWallet +
                double.parse(Constant.referralAmount.toString());
            transaction
                .update(userDocRef, {'walletAmount': newWallet.toString()});
          });

          WalletTransactionModel transactionModel = WalletTransactionModel(
              id: Constant.getUuid(),
              amount: Constant.referralAmount.toString(),
              createdDate: Timestamp.now(),
              paymentType: "Wallet",
              transactionId: orderModel.id,
              userId: referralUserId,
              orderType: "city",
              userType: "customer",
              note: "Referral Amount");

          await FireStoreUtils.setWalletTransaction(transactionModel);
        } catch (error) {
          log('updateReferralAmount error: $error');
        }
      }
    }
  }

  static Future<bool> getIntercityFirstOrderOrNOt(
      InterCityOrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future updateIntercityReferralAmount(
      InterCityOrderModel orderModel) async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(orderModel.userId)
        .get()
        .then((value) {
      if (value.data() != null) {
        referralModel = ReferralModel.fromJson(value.data()!);
      } else {
        return;
      }
    });
    if (referralModel != null) {
      if (referralModel!.referralBy != null &&
          referralModel!.referralBy!.isNotEmpty) {
        try {
          final referralUserId = referralModel!.referralBy!;
          final userDocRef =
              fireStore.collection(CollectionName.users).doc(referralUserId);
          await fireStore.runTransaction((transaction) async {
            final snapshot = await transaction.get(userDocRef);
            if (!snapshot.exists || snapshot.data() == null) return;
            final currentWallet = double.parse(
                (snapshot.data()!['walletAmount'] ?? '0').toString());
            final newWallet = currentWallet +
                double.parse(Constant.referralAmount.toString());
            transaction
                .update(userDocRef, {'walletAmount': newWallet.toString()});
          });

          WalletTransactionModel transactionModel = WalletTransactionModel(
              id: Constant.getUuid(),
              amount: Constant.referralAmount.toString(),
              createdDate: Timestamp.now(),
              paymentType: "Wallet",
              transactionId: orderModel.id,
              userId: orderModel.driverId.toString(),
              orderType: "intercity",
              userType: "customer",
              note: "Referral Amount");

          await FireStoreUtils.setWalletTransaction(transactionModel);
        } catch (error) {
          log('updateIntercityReferralAmount error: $error');
        }
      }
    }
  }

  static Future<UserModel?> getUserProfile(String uuid) async {
    UserModel? userModel;
    await fireStore
        .collection(CollectionName.users)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        userModel = UserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      userModel = null;
    });
    return userModel;
  }

  static Future<DriverUserModel?> getDriver(String uuid) async {
    DriverUserModel? driverUserModel;
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(uuid)
        .get()
        .then((value) {
      if (value.exists) {
        driverUserModel = DriverUserModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverUserModel = null;
    });
    return driverUserModel;
  }

  static Future<bool> updateUser(UserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.users)
        .doc(userModel.id)
        .set(userModel.toJson())
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<void> updateUserLanguage(String langCode) async {
    final uid = getCurrentUid();
    if (uid.isEmpty) return;
    await fireStore.collection(CollectionName.users).doc(uid).update({
      'language': langCode,
    });
  }

  static Future<bool> updateDriver(DriverUserModel userModel) async {
    bool isUpdate = false;
    await fireStore
        .collection(CollectionName.driverUsers)
        .doc(userModel.id)
        .set(userModel.toJson())
        .whenComplete(() {
      isUpdate = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isUpdate = false;
    });
    return isUpdate;
  }

  static Future<bool> getFirestOrderOrNOt(OrderModel orderModel) async {
    bool isFirst = true;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: orderModel.userId)
        .get()
        .then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future<bool?> rejectRide(
      OrderModel orderModel, DriverIdAcceptReject driverIdAcceptReject) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .collection("rejectedDriver")
        .doc(driverIdAcceptReject.driverId)
        .set(driverIdAcceptReject.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<OrderModel?> getOrder(String orderId) async {
    OrderModel? orderModel;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<InterCityOrderModel?> getInterCityOrder(String orderId) async {
    InterCityOrderModel? orderModel;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        orderModel = InterCityOrderModel.fromJson(value.data()!);
      }
    });
    return orderModel;
  }

  static Future<bool> userExitOrNot(String uid) async {
    bool isExit = false;

    await fireStore.collection(CollectionName.users).doc(uid).get().then(
      (value) {
        if (value.exists) {
          isExit = true;
        } else {
          isExit = false;
        }
      },
    ).catchError((error) {
      log("Failed to update user: $error");
      isExit = false;
    });
    return isExit;
  }

  static Future<List<ServiceModel>> getService() async {
    List<ServiceModel> serviceList = [];
    await fireStore
        .collection(CollectionName.service)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      log('📋 Services found: ${value.docs.length}');
      for (var element in value.docs) {
        try {
          ServiceModel documentModel = ServiceModel.fromJson(element.data());
          documentModel.id = element.id;
          serviceList.add(documentModel);
          log('✅ Service loaded: id=${element.id}, kmCharge=${documentModel.kmCharge}, basicFare=${documentModel.basicFare}, basicFareCharge=${documentModel.basicFareCharge}, perMinuteCharge=${documentModel.perMinuteCharge}');
        } catch (e) {
          log('❌ Error parsing service doc ${element.id}: $e\nData: ${element.data()}');
        }
      }
    }).catchError((error) {
      log('❌ Error loading services: $error');
    });
    return serviceList;
  }

  static Future<List<BannerModel>> getBanner() async {
    List<BannerModel> bannerList = [];
    try {
      // Try with ordering first
      QuerySnapshot? snapshot;
      try {
        snapshot = await fireStore
            .collection(CollectionName.banner)
            .where('enable', isEqualTo: true)
            .orderBy('position', descending: false)
            .get();
      } catch (e) {
        // If composite index doesn't exist, query without ordering
        log('⚠️ Banner ordered query failed (missing index?), trying without order: $e');
        snapshot = await fireStore
            .collection(CollectionName.banner)
            .where('enable', isEqualTo: true)
            .get();
      }

      log('📢 Banner query returned ${snapshot.docs.length} documents');
      for (var element in snapshot.docs) {
        final data = element.data() as Map<String, dynamic>;
        log('📢 Banner doc: id=${element.id}, image=${data['image']}, enable=${data['enable']}, isDeleted=${data['isDeleted']}');
        // Skip deleted banners (field may not exist in older documents)
        if (data['isDeleted'] == true) continue;
        BannerModel documentModel = BannerModel.fromJson(data);
        if (documentModel.image != null && documentModel.image!.isNotEmpty) {
          bannerList.add(documentModel);
        }
      }
    } catch (error) {
      log('❌ Banner fetch error: $error');
    }
    log('📢 Final banner list: ${bannerList.length} banners');
    return bannerList;
  }

  static Future<List<IntercityServiceModel>> getIntercityService() async {
    List<IntercityServiceModel> serviceList = [];
    await fireStore
        .collection(CollectionName.intercityService)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        IntercityServiceModel documentModel =
            IntercityServiceModel.fromJson(element.data());
        serviceList.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return serviceList;
  }

  static Future<bool?> setOrder(OrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  StreamController<List<DriverUserModel>>? getNearestOrderRequestController;

  Stream<List<DriverUserModel>> sendOrderData(OrderModel orderModel) async* {
    getNearestOrderRequestController ??=
        StreamController<List<DriverUserModel>>.broadcast();

    List<DriverUserModel> ordersList = [];

    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.driverUsers)
        .where('serviceId', isEqualTo: orderModel.serviceId)
        .where('zoneIds', arrayContains: orderModel.zoneId)
        .where('isOnline', isEqualTo: true);

    GeoFirePoint center = Geoflutterfire().point(
        latitude: orderModel.sourceLocationLAtLng?.latitude ?? 0.0,
        longitude: orderModel.sourceLocationLAtLng?.longitude ?? 0.0);
    Stream<List<DocumentSnapshot>> stream = Geoflutterfire()
        .collection(collectionRef: query)
        .within(
            center: center,
            radius: double.parse(Constant.radius),
            field: 'position',
            strictMode: true);

    stream.listen((List<DocumentSnapshot> documentList) {
      ordersList.clear();
      if (getNearestOrderRequestController != null) {
        for (var document in documentList) {
          final data = document.data() as Map<String, dynamic>;

          DriverUserModel orderModel = DriverUserModel.fromJson(data);

          ordersList.add(orderModel);
        }

        if (!getNearestOrderRequestController!.isClosed) {
          getNearestOrderRequestController!.sink.add(ordersList);
        }
        closeStream();
      }
    });
    if (getNearestOrderRequestController != null) {
      yield* getNearestOrderRequestController!.stream;
    }
  }

  Future<List<DriverUserModel>> sendOrderDataFuture(
      OrderModel orderModel) async {
    List<DriverUserModel> ordersList = [];

    Query<Map<String, dynamic>> query = fireStore
        .collection(CollectionName.driverUsers)
        .where('serviceId', isEqualTo: orderModel.serviceId)
        .where('zoneIds', arrayContains: orderModel.zoneId)
        .where('isOnline', isEqualTo: true);

    GeoFirePoint center = Geoflutterfire().point(
      latitude: orderModel.sourceLocationLAtLng?.latitude ?? 0.0,
      longitude: orderModel.sourceLocationLAtLng?.longitude ?? 0.0,
    );

    // Fetching documents using GeoFlutterFire's `within` function.
    List<DocumentSnapshot> documentList = await Geoflutterfire()
        .collection(collectionRef: query)
        .within(
          center: center,
          radius: double.parse(Constant.radius),
          field: 'position',
          strictMode: true,
        )
        .first; // Get the first batch of documents.

    for (var document in documentList) {
      final data = document.data() as Map<String, dynamic>;
      DriverUserModel orderModel = DriverUserModel.fromJson(data);
      ordersList.add(orderModel);
    }

    return ordersList;
  }

  closeStream() {
    if (getNearestOrderRequestController != null) {
      getNearestOrderRequestController!.close();
      getNearestOrderRequestController = null;
    }
  }

  static Future<bool?> setInterCityOrder(InterCityOrderModel orderModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderModel.id)
        .set(orderModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  /// Get online drivers whose zoneIds contain [zoneId].
  /// Used for intercity order notifications (no geo-radius needed).
  static Future<List<DriverUserModel>> getDriversInZoneForIntercity(
      String zoneId) async {
    List<DriverUserModel> drivers = [];
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await fireStore
          .collection(CollectionName.driverUsers)
          .where('zoneIds', arrayContains: zoneId)
          .where('isOnline', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        DriverUserModel driver = DriverUserModel.fromJson(doc.data());
        drivers.add(driver);
      }
    } catch (e) {
      log("getDriversInZoneForIntercity error: $e");
    }
    return drivers;
  }

  static Future<DriverIdAcceptReject?> getAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<DriverIdAcceptReject?> getInterCItyAcceptedOrders(
      String orderId, String driverId) async {
    DriverIdAcceptReject? driverIdAcceptReject;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .doc(orderId)
        .collection("acceptedDriver")
        .doc(driverId)
        .get()
        .then((value) async {
      if (value.exists) {
        driverIdAcceptReject = DriverIdAcceptReject.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      driverIdAcceptReject = null;
    });
    return driverIdAcceptReject;
  }

  static Future<OrderModel?> getOrderById(String orderId) async {
    OrderModel? orderModel;
    await fireStore
        .collection(CollectionName.orders)
        .doc(orderId)
        .get()
        .then((value) async {
      if (value.exists) {
        orderModel = OrderModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      orderModel = null;
    });
    return orderModel;
  }

  Future<PaymentModel?> getPayment() async {
    PaymentModel? paymentModel;
    try {
      await fireStore
          .collection(CollectionName.settings)
          .doc("payment")
          .get()
          .then((value) {
        if (value.exists && value.data() != null) {
          paymentModel = PaymentModel.fromJson(value.data()!);
        } else {
          // Return default payment model with Bankily enabled
          paymentModel = PaymentModel(
            bankily: Wallet(enable: true, name: 'Bankily'),
            cash: Wallet(enable: false, name: 'Cash'),
          );
        }
      });
    } catch (e) {
      log('Error getting payment settings: $e');
      // Return default payment model on error
      paymentModel = PaymentModel(
        bankily: Wallet(enable: true, name: 'Bankily'),
        cash: Wallet(enable: false, name: 'Cash'),
      );
    }
    return paymentModel;
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currencyModel;
    await fireStore
        .collection(CollectionName.currency)
        .where("enable", isEqualTo: true)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        currencyModel = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currencyModel;
  }

  Future<List<TaxModel>?> getTaxList() async {
    List<TaxModel> taxList = [];

    await fireStore
        .collection(CollectionName.tax)
        .where('country', isEqualTo: Constant.country)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        TaxModel taxModel = TaxModel.fromJson(element.data());
        taxList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return taxList;
  }

  Future<List<CouponModel>?> getCoupon() async {
    List<CouponModel> couponModel = [];

    await fireStore
        .collection(CollectionName.coupon)
        .where('enable', isEqualTo: true)
        .where("isPublic", isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .where('validity', isGreaterThanOrEqualTo: Timestamp.now())
        .get()
        .then((value) {
      for (var element in value.docs) {
        CouponModel taxModel = CouponModel.fromJson(element.data());
        couponModel.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return couponModel;
  }

  static Future<bool?> setReview(ReviewModel reviewModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.reviewDriver)
        .doc(reviewModel.id)
        .set(reviewModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<ReviewModel?> getReview(String orderId) async {
    ReviewModel? reviewModel;
    await fireStore
        .collection(CollectionName.reviewDriver)
        .doc(orderId)
        .get()
        .then((value) {
      if (value.data() != null) {
        reviewModel = ReviewModel.fromJson(value.data()!);
      }
    });
    return reviewModel;
  }

  static Future<List<WalletTransactionModel>?> getWalletTransaction() async {
    List<WalletTransactionModel> walletTransactionModel = [];

    await fireStore
        .collection(CollectionName.walletTransaction)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .orderBy('createdDate', descending: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        WalletTransactionModel taxModel =
            WalletTransactionModel.fromJson(element.data());
        walletTransactionModel.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return walletTransactionModel;
  }

  static Future<bool?> setWalletTransaction(
      WalletTransactionModel walletTransactionModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.walletTransaction)
        .doc(walletTransactionModel.id)
        .set(walletTransactionModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<bool?> updateUserWallet({required String amount}) async {
    try {
      final uid = FireStoreUtils.getCurrentUid();
      final docRef = fireStore.collection(CollectionName.users).doc(uid);
      await fireStore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw Exception('User not found');
        }
        final currentWallet =
            double.parse((snapshot.data()!['walletAmount'] ?? '0').toString());
        final newWallet = currentWallet + double.parse(amount);
        transaction.update(docRef, {'walletAmount': newWallet.toString()});
      });
      return true;
    } catch (e) {
      log('updateUserWallet transaction error: $e');
      return false;
    }
  }

  static Future<bool?> updateDriverWallet(
      {required String driverId, required String amount}) async {
    try {
      final docRef =
          fireStore.collection(CollectionName.driverUsers).doc(driverId);
      await fireStore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists || snapshot.data() == null) {
          throw Exception('Driver not found');
        }
        final currentWallet =
            double.parse((snapshot.data()!['walletAmount'] ?? '0').toString());
        final newWallet = currentWallet + double.parse(amount);
        transaction.update(docRef, {'walletAmount': newWallet.toString()});
      });
      return true;
    } catch (e) {
      log('updateDriverWallet transaction error: $e');
      return false;
    }
  }

  static Future<List<LanguageModel>?> getLanguage() async {
    List<LanguageModel> languageList = [];

    await fireStore
        .collection(CollectionName.languages)
        .where("enable", isEqualTo: true)
        .where("isDeleted", isEqualTo: false)
        .get()
        .then((value) {
      for (var element in value.docs) {
        LanguageModel taxModel = LanguageModel.fromJson(element.data());
        languageList.add(taxModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return languageList;
  }

  static Future<ReferralModel?> getReferral() async {
    ReferralModel? referralModel;
    await fireStore
        .collection(CollectionName.referral)
        .doc(FireStoreUtils.getCurrentUid())
        .get()
        .then((value) {
      if (value.exists) {
        referralModel = ReferralModel.fromJson(value.data()!);
      }
    }).catchError((error) {
      log("Failed to update user: $error");
      referralModel = null;
    });
    return referralModel;
  }

  static Future<bool?> checkReferralCodeValidOrNot(String referralCode) async {
    bool? isExit;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        if (value.size > 0) {
          isExit = true;
        } else {
          isExit = false;
        }
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return isExit;
  }

  static Future<ReferralModel?> getReferralUserByCode(
      String referralCode) async {
    ReferralModel? referralModel;
    try {
      await fireStore
          .collection(CollectionName.referral)
          .where("referralCode", isEqualTo: referralCode)
          .get()
          .then((value) {
        referralModel = ReferralModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return referralModel;
  }

  static Future<String?> referralAdd(ReferralModel ratingModel) async {
    try {
      await fireStore
          .collection(CollectionName.referral)
          .doc(ratingModel.id)
          .set(ratingModel.toJson());
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return null;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await fireStore
        .collection(CollectionName.onBoarding)
        .where("type", isEqualTo: "customerApp")
        .get()
        .then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel =
            OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  static Future addInBox(InboxModel inboxModel) async {
    return await fireStore
        .collection("chat")
        .doc(inboxModel.orderId)
        .set(inboxModel.toJson())
        .then((document) {
      return inboxModel;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    return await fireStore
        .collection("chat")
        .doc(conversationModel.orderId)
        .collection("thread")
        .doc(conversationModel.id)
        .set(conversationModel.toJson())
        .then((document) {
      return conversationModel;
    });
  }

  static Future<List<FaqModel>> getFaq() async {
    List<FaqModel> faqModel = [];
    await fireStore
        .collection(CollectionName.faq)
        .where('enable', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        FaqModel documentModel = FaqModel.fromJson(element.data());
        faqModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return faqModel;
  }

  static Future<bool?> deleteUser() async {
    bool? isDelete;
    try {
      // IMPORTANT: Delete Firebase Auth user FIRST, then Firestore data.
      // If Auth deletion fails (e.g. requires-recent-login), we don't lose user data.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final uid = currentUser.uid;
        await currentUser.delete();

        // Auth deletion succeeded — now safe to delete Firestore data
        await fireStore.collection(CollectionName.users).doc(uid).delete();

        isDelete = true;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        log('FireStoreUtils.deleteUser requires recent login - user needs to re-authenticate');
        return false;
      }
      log('FireStoreUtils.deleteUser FirebaseAuthException: $e');
      return false;
    } catch (e, s) {
      log('FireStoreUtils.deleteUser $e $s');
      return false;
    }
    return isDelete;
  }

  static Future<bool?> setSOS(SosModel sosModel) async {
    bool isAdded = false;
    await fireStore
        .collection(CollectionName.sos)
        .doc(sosModel.id)
        .set(sosModel.toJson())
        .then((value) {
      isAdded = true;
    }).catchError((error) {
      log("Failed to update user: $error");
      isAdded = false;
    });
    return isAdded;
  }

  static Future<SosModel?> getSOS(String orderId) async {
    SosModel? sosModel;
    try {
      await fireStore
          .collection(CollectionName.sos)
          .where("orderId", isEqualTo: orderId)
          .get()
          .then((value) {
        sosModel = SosModel.fromJson(value.docs.first.data());
      });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return null;
    }
    return sosModel;
  }

  Future<List<AriPortModel>?> getAirports() async {
    List<AriPortModel> airPortList = [];

    await fireStore
        .collection(CollectionName.airPorts)
        .where('cityLocation', isEqualTo: Constant.city)
        .get()
        .then((value) {
      for (var element in value.docs) {
        AriPortModel ariPortModel = AriPortModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return airPortList;
  }

  static Future<bool> paymentStatusCheck() async {
    ShowToastDialog.showLoader("Please wait");
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.orders)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.rideComplete)
        .where("paymentStatus", isEqualTo: false)
        .get()
        .then((value) {
      ShowToastDialog.closeLoader();
      // Exclude cash payment rides - driver handles cash confirmation
      final nonCashUnpaid = value.docs.where((doc) {
        final data = doc.data();
        return data['paymentType'] != 'Cash';
      }).toList();
      if (nonCashUnpaid.isNotEmpty) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future<bool> paymentStatusCheckIntercity() async {
    ShowToastDialog.showLoader("Please wait");
    bool isFirst = false;
    await fireStore
        .collection(CollectionName.ordersIntercity)
        .where('userId', isEqualTo: FireStoreUtils.getCurrentUid())
        .where("status", isEqualTo: Constant.rideComplete)
        .where("paymentStatus", isEqualTo: false)
        .get()
        .then((value) {
      ShowToastDialog.closeLoader();
      // Exclude cash payment rides - driver handles cash confirmation
      final nonCashUnpaid = value.docs.where((doc) {
        final data = doc.data();
        return data['paymentType'] != 'Cash';
      }).toList();
      log(nonCashUnpaid.length.toString());
      if (nonCashUnpaid.isNotEmpty) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  Future<List<ZoneModel>?> getZone() async {
    List<ZoneModel> airPortList = [];
    await fireStore
        .collection(CollectionName.zone)
        .where('publish', isEqualTo: true)
        .get()
        .then((value) {
      for (var element in value.docs) {
        ZoneModel ariPortModel = ZoneModel.fromJson(element.data());
        airPortList.add(ariPortModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    airPortList
        .sort((a, b) => (a.position ?? 999999).compareTo(b.position ?? 999999));
    return airPortList;
  }
}
