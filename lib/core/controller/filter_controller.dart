import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kitab_mandi/features/dashboard/controller/home_controller.dart';

class FilterController extends GetxController {
  /// ================= DATA =================
  var categoriesData = [].obs;

  var selectedCategory = ''.obs;
  var selectedSubCategory = ''.obs;
  var selectedType = ''.obs;

  final selectedConditions = <String>[].obs;
  final selectedSort = ''.obs;

  final selectedDistanceKm = 0.0.obs;
  final minPrice = 0.0.obs;
  final maxPrice = 5000.0.obs;

  /// ================= INIT =================
  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// ================= LOAD JSON =================
  Future<void> loadCategories() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/categories.json',
    );

    final data = json.decode(jsonString);
    categoriesData.value = data['categories'];
  }

  /// ================= HELPERS =================

  dynamic safeFind(List list, bool Function(dynamic) test) {
    try {
      return list.firstWhere(test);
    } catch (e) {
      return null;
    }
  }

  List get subCategories {
    final cat = safeFind(
      categoriesData,
      (e) => e['name'] == selectedCategory.value,
    );

    return cat?['subcategories'] ?? [];
  }

  List get types {
    final sub = safeFind(
      subCategories,
      (e) => e['name'] == selectedSubCategory.value,
    );

    return sub?['children'] ?? [];
  }

  /// ================= TOGGLE =================
  void toggleItem(RxList<String> list, String value) {
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
  }

  /// ================= APPLY FILTER =================
  // void applyFilters() {
  //   final homeController = Get.find<HomeController>();

  //   final filtered = homeController.listings.where((item) {
  //     /// CATEGORY FILTER
  //     if (selectedCategory.value.isNotEmpty &&
  //         item.category['name'] != selectedCategory.value) {
  //       return false;
  //     }

  //     /// SUB CATEGORY FILTER
  //     if (selectedSubCategory.value.isNotEmpty &&
  //         item.category['subCategory'] != selectedSubCategory.value) {
  //       return false;
  //     }

  //     /// TYPE FILTER
  //     if (selectedType.value.isNotEmpty &&
  //         item.category['type'] != selectedType.value) {
  //       return false;
  //     }

  //     /// PRICE FILTER
  //     final price = (item.price).toDouble();
  //     if (price < minPrice.value || price > maxPrice.value) {
  //       return false;
  //     }

  //     /// CONDITION FILTER
  //     if (selectedConditions.isNotEmpty &&
  //         !selectedConditions.contains(item.condition)) {
  //       return false;
  //     }

  //     /// DISTANCE FILTER (optional)
  //     if (selectedDistanceKm.value > 0) {
  //       final distance = item.distanceKm ?? 0.0;
  //       if (distance > selectedDistanceKm.value) {
  //         return false;
  //       }
  //     }

  //     return true;
  //   }).toList();

  //   /// APPLY TO HOME
  //   // homeController.filteredListings.value = filtered;

  //   /// SORTING
  //   if (selectedSort.value.isNotEmpty) {
  //     if (selectedSort.value == "price_low_to_high") {
  //       filtered.sort((a, b) => a.price.compareTo(b.price));
  //     } else if (selectedSort.value == "price_high_to_low") {
  //       filtered.sort((a, b) => b.price.compareTo(a.price));
  //     } else if (selectedSort.value == "latest") {
  //       filtered.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  //     }
  //   }

  //   // homeController.filteredListings.refresh();
  // }

  /// ================= RESET =================
  void reset() {
    selectedCategory.value = '';
    selectedSubCategory.value = '';
    selectedType.value = '';

    selectedConditions.clear();
    selectedSort.value = '';

    minPrice.value = 0;
    maxPrice.value = 5000;
    selectedDistanceKm.value = 0;

    final homeController = Get.find<HomeController>();

    /// RESET LIST
    // homeController.filteredListings.value = homeController.listings;

    homeController.defaultRadiusKm = 10;
  }
}
