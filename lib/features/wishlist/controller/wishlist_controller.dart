import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitab_mandi/features/dashboard/model/listing_model.dart';

class WishlistController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ///  OBSERVABLE LIST
  RxList<ListingModel> wishlist = <ListingModel>[].obs;

  ///  LOADING
  RxBool isLoading = false.obs;

  ///  CURRENT USER ID
  String? get userId => _auth.currentUser?.uid;

  /// ================= FETCH WISHLIST =================
  @override
  void onInit() {
    super.onInit();
    fetchWishlist();
  }

  void fetchWishlist() {
    try {
      if (userId == null) return;

      isLoading.value = true;

      _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            wishlist.value = snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // store listingId
              return ListingModel.fromMap(data, doc.id);
            }).toList();

            isLoading.value = false;
          });
    } catch (e) {
      isLoading.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// ================= ADD TO WISHLIST =================
  Future<void> addToWishlist(ListingModel item) async {
    try {
      if (userId == null) return;

      final listingId = item.id;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(listingId)
          .set({...item.toMap(), "createdAt": FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint("Add wishlist error: $e");
    }
  }

  /// ================= REMOVE =================
  Future<void> removeFromWishlist(String listingId) async {
    try {
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .doc(listingId)
          .delete();
    } catch (e) {
      debugPrint("Remove wishlist error: $e");
    }
  }

  /// ================= TOGGLE ❤️ =================
  Future<void> toggleWishlist(ListingModel item) async {
    final listingId = item.id;
    if (isFavorite(listingId)) {
      await removeFromWishlist(listingId);
    } else {
      await addToWishlist(item);
    }
  }

  /// ================= CHECK FAVORITE =================
  bool isFavorite(String listingId) {
    return wishlist.any((item) => item.id == listingId);
  }
}
