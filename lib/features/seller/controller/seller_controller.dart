import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kitab_mandi/features/dashboard/controller/home_controller.dart';
import 'package:kitab_mandi/features/dashboard/controller/my_ads_controller.dart';
import 'package:kitab_mandi/features/dashboard/model/listing_model.dart';
import 'package:kitab_mandi/core/utils/app_snackbar.dart';
import 'package:kitab_mandi/routes/app_routes.dart';

class SellerController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  /// ================= TEXT CONTROLLERS =================
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  ListingModel? listingModel;

  RxBool isEdit = false.obs;
  String? listingId;

  final List<String> removedImageUrls = [];

  /// ================= LOCATION =================
  RxString state = "".obs;
  RxString city = "".obs;
  RxString locality = "".obs;
  RxString subLocality = "".obs;
  RxString postalCode = "".obs;
  RxDouble lat = 0.0.obs;
  RxDouble long = 0.0.obs;
  RxString fullAddress = "".obs;

  RxBool isDetectingLocation = false.obs;
  RxBool isUploading = false.obs;

  final myAdsCtrl = Get.find<MyAdsController>();

  /// ================= CATEGORY =================
  RxList categories = [].obs;

  RxString selectedMain = "".obs;
  RxString selectedSub = "".obs;
  RxString selectedChild = "".obs;

  List get subCategories {
    final main = categories.firstWhereOrNull(
      (e) => e["name"] == selectedMain.value,
    );
    return main?["subcategories"] ?? [];
  }

  List<Map<String, dynamic>> get childCategories {
    final sub = subCategories.firstWhereOrNull(
      (e) => e["name"] == selectedSub.value,
    );

    final children = sub?["children"];

    if (children is List) {
      return children.expand<Map<String, dynamic>>((e) {
        if (e is List) {
          return e.map((item) => Map<String, dynamic>.from(item));
        } else if (e is Map) {
          return [Map<String, dynamic>.from(e)];
        }
        return [];
      }).toList();
    }

    return [];
  }

  /// ================= DYNAMIC TITLES =================
  String get subTitle {
    if (selectedMain.value == "School Books") return "Board";
    if (selectedMain.value == "Academic Books") return "Stream";
    if (selectedMain.value == "Competitive Exams") return "Exam Type";
    return "Sub Category";
  }

  String get childTitle {
    if (selectedMain.value == "School Books") return "Class";
    if (selectedMain.value == "Academic Books") return "Branch";
    if (selectedMain.value == "Competitive Exams") return "Exam";
    return "Type";
  }

  /// ================= CONDITION =================
  RxString selectedCondition = "".obs;
  final conditions = ["New", "Like New", "Used"];

  /// ================= IMAGES =================
  RxList<String> images = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();

    if (Get.arguments != null) {
      final arg = Get.arguments;
      listingModel = arg['listing'];
      city.value = listingModel?.location['city'] ?? "";
      state.value = listingModel?.location['state'] ?? "";
      subLocality.value = listingModel?.location['subLocality'] ?? "";
      postalCode.value = listingModel?.location['postalCode'] ?? "";
      lat.value = listingModel?.location['lat'] ?? 0.0;
      long.value = listingModel?.location['long'] ?? 0.0;

      ///  BUILD FULL ADDRESS (CLEAN)
      fullAddress.value =
          "${subLocality.value}, ${locality.value}, ${city.value}, ${state.value} - ${postalCode.value}"
              .replaceAll(RegExp(r'(, )+'), ', ')
              .replaceAll(RegExp(r'^, |, $'), '');
      isEdit.value = true;
      listingId = listingModel!.id;
      _prefillData();
    }
  }

  /// ================= LOAD JSON =================
  Future<void> loadCategories() async {
    final data = await rootBundle.loadString('assets/data/categories.json');
    final jsonData = json.decode(data);
    categories.value = jsonData["categories"];
  }

  /// ================= PREFILL =================
  void _prefillData() {
    if (listingModel == null) return;

    titleController.text = listingModel!.title;
    priceController.text = listingModel!.price.toString();
    descriptionController.text = listingModel!.description;

    final cat = listingModel!.category;
    selectedMain.value = cat["main"] ?? "";
    selectedSub.value = cat["sub"] ?? "";
    selectedChild.value = cat["child"] ?? "";

    selectedCondition.value = listingModel!.condition;

    images.assignAll(listingModel!.images);
  }

  /// ================= IMAGE =================
  Future<void> pickImage() async {
    if (images.length >= 3) {
      AppSnackbar.error("Max 3 images allowed");
      return;
    }

    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) images.add(img.path);
  }

  void removeImage(int index) {
    final img = images[index];
    if (img.startsWith("http")) removedImageUrls.add(img);
    images.removeAt(index);
  }

  /// ================= LOCATION =================
  Future<void> detectLocation() async {
    try {
      isDetectingLocation.value = true;

      final pos = await Geolocator.getCurrentPosition();
      final place = await placemarkFromCoordinates(pos.latitude, pos.longitude);

      final p = place.first;

      city.value = p.locality ?? "";
      state.value = p.administrativeArea ?? "";
      locality.value = p.locality ?? "";
      subLocality.value = p.subLocality ?? "";
      postalCode.value = p.postalCode ?? "";

      lat.value = pos.latitude;
      long.value = pos.longitude;

      ///  BUILD FULL ADDRESS (CLEAN)
      fullAddress.value =
          "${subLocality.value}, ${locality.value}, ${city.value}, ${state.value} - ${postalCode.value}"
              .replaceAll(RegExp(r'(, )+'), ', ')
              .replaceAll(RegExp(r'^, |, $'), '');

      AppSnackbar.success("Location detected");
    } catch (e) {
      AppSnackbar.error("Location failed");
    } finally {
      isDetectingLocation.value = false;
    }
  }

  /// ================= VALIDATION =================
  bool validate() {
    if (images.isEmpty) return _err("Please upload at least 1 image");

    if (selectedMain.value.isEmpty) {
      return _err("Please select main category");
    }

    if (selectedSub.value.isEmpty) {
      return _err("Please select ${subTitle.toLowerCase()}");
    }

    ///  ONLY validate child if exists
    if (childCategories.isNotEmpty && selectedChild.value.isEmpty) {
      return _err("Please select ${childTitle.toLowerCase()}");
    }

    final title = titleController.text.trim();
    if (title.isEmpty) return _err("Title is required");
    if (title.length < 5) return _err("Title must be at least 5 characters");

    final priceText = priceController.text.trim();
    if (priceText.isEmpty) return _err("Price is required");

    final price = int.tryParse(priceText);
    if (price == null) return _err("Enter valid price");
    if (price <= 0) return _err("Price must be greater than 0");
    if (price > 100000) return _err("Price too high");

    final desc = descriptionController.text.trim();
    if (desc.isEmpty) return _err("Description is required");
    if (desc.length < 10) return _err("Description too short");

    if (selectedCondition.value.isEmpty) {
      return _err("Select item condition");
    }

    if (fullAddress.value.isEmpty) {
      return _err("Please detect location");
    }
    return true;
  }

  bool _err(String msg) {
    AppSnackbar.error(msg);
    return false;
  }

  /// ================= UPLOAD =================
  Future<void> uploadListing() async {
    final user = FirebaseAuth.instance.currentUser;

    ///  GET USER DATA FROM FIRESTORE
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user?.uid)
        .get();

    final userData = userDoc.data();
    if (!validate()) return;

    try {
      isUploading.value = true;

      final user = _auth.currentUser;
      if (user == null) return;

      List<String> finalImages = [];

      for (var img in images) {
        if (img.startsWith("http")) {
          finalImages.add(img);
        } else {
          final ref = _storage.ref().child(
            "listings/${DateTime.now().millisecondsSinceEpoch}.jpg",
          );
          await ref.putFile(File(img));
          finalImages.add(await ref.getDownloadURL());
        }
      }

      final data = {
        "title": titleController.text.trim(),
        "price": int.tryParse(priceController.text) ?? 0,
        "description": descriptionController.text.trim(),
        "category": {
          "main": selectedMain.value,
          "sub": selectedSub.value,
          "child": selectedChild.value,
        },
        "condition": selectedCondition.value,
        "images": finalImages,
        "location": {
          'lat': lat.value,
          'long': long.value,
          'fullAddress': fullAddress.value,
          'city': city.value,
          'state': state.value,
          'locality': locality.value,
          'subLocality': subLocality.value,
          'postalCode': postalCode.value,
        },
        "seller": {
          "uid": user.uid,
          "name": userData?["name"] ?? "",
          "email": user.email ?? "",
        },
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (isEdit.value) {
        await _firestore.collection("listings").doc(listingId).update(data);
      } else {
        final doc = _firestore.collection("listings").doc();
        await doc.set({...data, "id": doc.id});
      }

      Get.offAllNamed(AppRoutes.dashboard);

      if (Get.isRegistered<HomeController>()) {}
      if (Get.isRegistered<MyAdsController>()) {
        Get.find<MyAdsController>().fetchMyAds();
      }
    } catch (e) {
      AppSnackbar.error("Upload failed");
    } finally {
      isUploading.value = false;
    }
  }
}
