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

  @override
  void onInit() {
    super.onInit();

    ///  Listen to location changes
    ever(locationCtrl.latitude, (_) {
      _onLocationChanged();
    });

    ever(locationCtrl.longitude, (_) {
      _onLocationChanged();
    });
  }

  Future<void> _init() async {
    Future.wait([fetchTopViewedListings(), fetchAllListings()]);
  }

  void _onLocationChanged() {
    /// Avoid calling when location is 0
    if (locationCtrl.latitude.value == 0.0 ||
        locationCtrl.longitude.value == 0.0) {
      return;
    }

    /// Refresh listings
    fetchTopViewedListings();
    fetchAllListings();
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

    /// Safety check (important)
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

      /// 🔥 Fetch MORE data (important)
      final snapshot = await _firestore
          .collection("listings")
          .orderBy("createdAt", descending: true)
          .limit(100) // 👈 NOT 20
          .get();

      final all = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
          .toList();

      /// ✅ Step 1: Filter within 5 KM
      final nearby = all.where((item) {
        final distance = calculateDistance(
          sellerLat: item.lat,
          sellerLong: item.long,
        );
        return distance <= 5.0;
      }).toList();

      /// ✅ Step 2: Sort by creation date (desc)
      nearby.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

      /// ✅ Step 3: Take top 20 OR all if less
      if (nearby.length > 20) {
        popularListingNearYou.value = nearby.take(20).toList();
      } else {
        popularListingNearYou.value = nearby;
      }
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

      final all = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
          .toList();

      ///  Apply 5 KM filter
      allListings.value = filterNearbyListings(all);
    } catch (e) {
      isLoading.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  List<ListingModel> filterNearbyListings(List<ListingModel> listings) {
    final radius = 5.0; // 5 KM

    final nearby = listings.where((item) {
      final distance = calculateDistance(
        sellerLat: item.lat,
        sellerLong: item.long,
      );

      return distance <= radius;
    }).toList();

    /// ✅ Sort by nearest (OLX style)
    nearby.sort((a, b) {
      final d1 = calculateDistance(sellerLat: a.lat, sellerLong: a.long);

      final d2 = calculateDistance(sellerLat: b.lat, sellerLong: b.long);

      return d1.compareTo(d2);
    });

    return nearby;
  }
}
