import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:kitab_mandi/core/controller/location_controller.dart';
import 'package:kitab_mandi/features/dashboard/model/listing_model.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RxList<ListingModel> popularListingNearYou = <ListingModel>[].obs;
  RxList<ListingModel> allListings = <ListingModel>[].obs;
  final locationCtrl = Get.put(LocationController());
  RxString searchQuery = "".obs;
  RxBool isLoading = true.obs;

  ///  Default Radius
  double defaultRadiusKm = 10.0;

  @override
  onReady() {
    super.onReady();
    _init();
  }

  Future<void> _init() async {
    Future.wait([fetchTopViewedListings(), fetchAllListings()]);
  }

  ///  Search
  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  ///  Distance (Haversine)
  double calculateDistance({
    required double sellerLat,
    required double sellerLong,
  }) {
    final userLat = locationCtrl.latitude.value;
    final userLong = locationCtrl.longitude.value;

    /// ⚠️ Safety check (important)
    if (userLat == 0.0 || userLong == 0.0) {
      return 0.0; // or return -1 to indicate unknown
    }

    const earthRadius = 6371; // KM

    final dLat = (sellerLat - userLat) * pi / 180;
    final dLon = (sellerLong - userLong) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * pi / 180) *
            cos(sellerLat * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final distance = earthRadius * c;

    return distance; // in KM
  }

  ///  Manual Fetch
  Future<void> fetchTopViewedListings() async {
    popularListingNearYou.value = [];
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection("listings")
          .where('views', isGreaterThan: 0)
          .orderBy("views", descending: true)
          .limit(10)
          .get();

      popularListingNearYou.value = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      isLoading.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAllListings() async {
    allListings.value = [];
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection("listings")
          .orderBy("createdAt", descending: true)
          .get();

      allListings.value = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      isLoading.value = false;
    } finally {
      isLoading.value = false;
    }
  }
}
