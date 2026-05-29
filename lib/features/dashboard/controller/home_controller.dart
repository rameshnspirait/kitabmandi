import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:kitab_mandi/core/controller/filter_controller.dart';
import 'package:kitab_mandi/core/controller/location_controller.dart';
import 'package:kitab_mandi/features/dashboard/model/listing_model.dart';

class HomeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<ListingModel> listings = <ListingModel>[].obs;
  RxList<ListingModel> filteredListings = <ListingModel>[].obs;

  final filterCtrl = Get.put(FilterController());
  final locationCtrl = Get.put(LocationController());

  RxString searchQuery = "".obs;
  RxBool isLoading = true.obs;

  /// 🎯 Default Radius
  double defaultRadiusKm = 10.0;

  @override
  void onInit() {
    super.onInit();

    /// 🔥 Reactive filtering
    ever(searchQuery, (_) => applyFilters());
    ever(filterCtrl.selectedCategory, (_) => applyFilters());
    ever(filterCtrl.selectedSubCategory, (_) => applyFilters());
    ever(filterCtrl.selectedType, (_) => applyFilters());
    ever(filterCtrl.selectedConditions, (_) => applyFilters());
    ever(filterCtrl.selectedSort, (_) => applyFilters());
    ever(filterCtrl.minPrice, (_) => applyFilters());
    ever(filterCtrl.maxPrice, (_) => applyFilters());
    ever(filterCtrl.selectedDistanceKm, (_) => applyFilters());

    ever(locationCtrl.latitude, (_) => applyFilters());
    ever(locationCtrl.longitude, (_) => applyFilters());
  }

  @override
  onReady() {
    super.onReady();
    _init();
  }

  Future<void> _init() async {
    locationCtrl.loadInitialData();
    listenListings();
  }

  /// 📏 Distance (Haversine)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371;

    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 📡 Firestore Listener
  void listenListings() {
    isLoading.value = true;
    _firestore
        .collection("listings")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .listen((snapshot) {
          listings.value = snapshot.docs
              .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
              .toList();

          ///  SAFE CALL (avoids build conflict)
          Future.microtask(() {
            applyFilters();
          });

          isLoading.value = false;
        });
  }

  /// 🎯 MAIN FILTER ENGINE
  void applyFilters() {
    List<ListingModel> temp = List.from(listings);

    final userLat = locationCtrl.latitude.value;
    final userLng = locationCtrl.longitude.value;

    /// 🔍 SEARCH
    if (searchQuery.value.isNotEmpty) {
      temp = temp.where((item) {
        return item.title.toLowerCase().contains(
          searchQuery.value.toLowerCase(),
        );
      }).toList();
    }

    /// 📚 CATEGORY
    if (filterCtrl.selectedCategory.value.isNotEmpty) {
      temp = temp.where((item) {
        return item.mainCategory == filterCtrl.selectedCategory.value;
      }).toList();
    }

    /// 📂 SUB CATEGORY
    if (filterCtrl.selectedSubCategory.value.isNotEmpty) {
      temp = temp.where((item) {
        return item.subCategory == filterCtrl.selectedSubCategory.value;
      }).toList();
    }

    /// 🧩 TYPE
    if (filterCtrl.selectedType.value.isNotEmpty) {
      temp = temp.where((item) {
        return item.childCategory == filterCtrl.selectedType.value;
      }).toList();
    }

    /// 📦 CONDITION
    if (filterCtrl.selectedConditions.isNotEmpty) {
      temp = temp.where((item) {
        return filterCtrl.selectedConditions.contains(item.condition);
      }).toList();
    }

    /// 💰 PRICE RANGE
    temp = temp.where((item) {
      return item.price >= filterCtrl.minPrice.value &&
          item.price <= filterCtrl.maxPrice.value;
    }).toList();

    /// 📍 LOCATION FILTER
    if (userLat != 0.0 && userLng != 0.0) {
      final radius = filterCtrl.selectedDistanceKm.value > 0
          ? filterCtrl.selectedDistanceKm.value
          : defaultRadiusKm;

      List<ListingModel> locationFiltered = [];

      for (var item in temp) {
        final loc = item.location;

        final lat = double.tryParse(loc['lat'].toString());
        final lng = double.tryParse(loc['long'].toString());

        /// keep item if location invalid (optional)
        if (lat == null || lng == null) {
          locationFiltered.add(item);
          continue;
        }

        final distance = calculateDistance(userLat, userLng, lat, lng);
        item.distanceKm = distance;

        if (distance <= radius) {
          locationFiltered.add(item);
        }
      }

      temp = locationFiltered;
    }

    /// 🔄 SORTING
    switch (filterCtrl.selectedSort.value) {
      case "Price: Low to High":
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;

      case "Price: High to Low":
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;

      case "Newest First":
        temp.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        break;
    }

    /// ✅ FINAL UPDATE
    if (Get.isRegistered<HomeController>()) {
      Future.microtask(() {
        filteredListings.value = temp;
      });
    }
  }

  /// 🔍 Search
  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  /// 🔄 Manual Fetch
  Future<void> fetchListings() async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection("listings")
          .orderBy("createdAt", descending: true)
          .get();

      listings.value = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data(), doc.id))
          .toList();

      applyFilters();
    } finally {
      isLoading.value = false;
    }
  }
}
