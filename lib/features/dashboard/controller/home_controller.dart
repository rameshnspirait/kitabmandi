import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kitab_mandi/core/controller/filter_controller.dart';
import 'package:kitab_mandi/core/controller/location_controller.dart';
import 'package:kitab_mandi/features/dashboard/model/listing_model.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ================= LISTS =================

  /// 🔹 Firestore Data
  RxList<ListingModel> allListings = <ListingModel>[].obs;

  /// 🔹 After Search
  RxList<ListingModel> searchedListings = <ListingModel>[].obs;

  /// 🔹 Final UI Data
  RxList<ListingModel> filteredListings = <ListingModel>[].obs;

  /// 🔹 Top listings
  RxList<ListingModel> popularListingNearYou = <ListingModel>[].obs;

  /// ================= CONTROLLERS =================

  final locationCtrl = Get.put(LocationController());
  final filterCtrl = Get.put(FilterController());

  final searchCtrl = TextEditingController();
  RxString searchQuery = "".obs;

  RxBool isLoading = true.obs;

  double defaultRadiusKm = 10.0;

  /// ================= LIFECYCLE =================

  @override
  void onInit() {
    super.onInit();

    /// 🔁 Location change → reload data
    ever(locationCtrl.latitude, (_) => _onLocationChanged());
    ever(locationCtrl.longitude, (_) => _onLocationChanged());

    /// 🔁 Search change → apply filters
    debounce(
      searchQuery,
      (_) => applyAllFilters(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onReady() {
    super.onReady();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([fetchTopViewedListings(), fetchAllListings()]);
  }

  void _onLocationChanged() {
    if (locationCtrl.latitude.value == 0.0 ||
        locationCtrl.longitude.value == 0.0) {
      return;
    }

    fetchTopViewedListings();
    fetchAllListings();
  }

  /// ================= SEARCH =================

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  void applySearch() {
    if (searchQuery.value.isEmpty) {
      searchedListings.value = List.from(allListings);
    } else {
      final query = searchQuery.value.toLowerCase();
      searchedListings.value = allListings.where((item) {
        final title = item.title.toLowerCase();
        final desc = item.description.toLowerCase();

        return title.contains(query) || desc.contains(query);
      }).toList();
    }
  }

  /// ================= MAIN FILTER PIPELINE =================

  void applyAllFilters() {
    ///  Apply search first
    applySearch();

    List<ListingModel> tempList = List.from(searchedListings);

    /// 2️⃣ CATEGORY
    if (filterCtrl.selectedCategory.value.isNotEmpty) {
      tempList = tempList.where((item) {
        return item.mainCategory == filterCtrl.selectedCategory.value;
      }).toList();
    }

    /// 3️⃣ SUB CATEGORY
    if (filterCtrl.selectedSubCategory.value.isNotEmpty) {
      tempList = tempList.where((item) {
        return item.subCategory == filterCtrl.selectedSubCategory.value;
      }).toList();
    }

    /// 4️⃣ TYPE
    if (filterCtrl.selectedType.value.isNotEmpty) {
      tempList = tempList.where((item) {
        return item.childCategory == filterCtrl.selectedType.value;
      }).toList();
    }

    /// 5️⃣ PRICE
    tempList = tempList.where((item) {
      return item.price >= filterCtrl.minPrice.value &&
          item.price <= filterCtrl.maxPrice.value;
    }).toList();

    /// 6️⃣ CONDITION
    if (filterCtrl.selectedConditions.isNotEmpty) {
      tempList = tempList.where((item) {
        return filterCtrl.selectedConditions.contains(item.condition);
      }).toList();
    }

    /// 7️⃣ DISTANCE
    if (filterCtrl.selectedDistanceKm.value > 0) {
      tempList = tempList.where((item) {
        final distance = calculateDistance(
          sellerLat: item.lat,
          sellerLong: item.long,
        );
        return distance <= filterCtrl.selectedDistanceKm.value;
      }).toList();
    }

    /// 8️⃣ SORTING
    if (filterCtrl.selectedSort.value.isNotEmpty) {
      if (filterCtrl.selectedSort.value == "Price: Low to High") {
        tempList.sort((a, b) => a.price.compareTo(b.price));
      } else if (filterCtrl.selectedSort.value == "Price: High to Low") {
        tempList.sort((a, b) => b.price.compareTo(a.price));
      } else if (filterCtrl.selectedSort.value == "Newest First") {
        tempList.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      }
    } else {
      /// Default: nearest first
      tempList.sort((a, b) {
        final d1 = calculateDistance(sellerLat: a.lat, sellerLong: a.long);
        final d2 = calculateDistance(sellerLat: b.lat, sellerLong: b.long);
        return d1.compareTo(d2);
      });
    }

    ///  FINAL UPDATE
    filteredListings.value = tempList;
  }

  /// ================= DISTANCE =================

  double calculateDistance({
    required double sellerLat,
    required double sellerLong,
  }) {
    final userLat = locationCtrl.latitude.value;
    final userLong = locationCtrl.longitude.value;

    if (userLat == 0.0 || userLong == 0.0) return 0.0;

    const earthRadius = 6371;

    final dLat = (sellerLat - userLat) * pi / 180;
    final dLon = (sellerLong - userLong) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * pi / 180) *
            cos(sellerLat * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// ================= FETCH TOP =================

  Future<void> fetchTopViewedListings() async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection("listings")
          .orderBy("createdAt", descending: true)
          .limit(100)
          .get();

      final all = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
          .toList();

      final nearby = all.where((item) {
        final distance = calculateDistance(
          sellerLat: item.lat,
          sellerLong: item.long,
        );
        return distance <= 5.0;
      }).toList();

      nearby.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

      popularListingNearYou.value = nearby.length > 20
          ? nearby.take(20).toList()
          : nearby;
    } finally {
      isLoading.value = false;
    }
  }

  /// ================= FETCH ALL =================

  Future<void> fetchAllListings() async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection("listings")
          .orderBy("createdAt", descending: true)
          .get();

      final all = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
          .toList();

      allListings.value = filterNearbyListings(all);

      /// 🔥 VERY IMPORTANT
      applyAllFilters(); // refresh UI automatically
    } finally {
      isLoading.value = false;
    }
  }

  /// ================= NEARBY FILTER =================

  List<ListingModel> filterNearbyListings(List<ListingModel> listings) {
    final radius = 5.0;

    final nearby = listings.where((item) {
      final distance = calculateDistance(
        sellerLat: item.lat,
        sellerLong: item.long,
      );
      return distance <= radius;
    }).toList();

    nearby.sort((a, b) {
      final d1 = calculateDistance(sellerLat: a.lat, sellerLong: a.long);
      final d2 = calculateDistance(sellerLat: b.lat, sellerLong: b.long);
      return d1.compareTo(d2);
    });

    return nearby;
  }
}
