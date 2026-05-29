import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kitab_mandi/features/seller/controller/seller_controller.dart';
import 'package:kitab_mandi/widgets/app_text_field.dart';

class SellerListingView extends StatelessWidget {
  final controller = Get.put(SellerController());
  SellerListingView({super.key});

  Color _appBarBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1A1D23) : const Color(0xFFFFFFFF);
  }

  ///  Section Card Wrapper
  Widget sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }

  ///  Section Title
  Widget sectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  ///  Premium Chips
  Widget chipWrap({
    required List<String> items,
    required String selected,
    required Function(String) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item;

        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          selectedColor: Get.theme.colorScheme.primary.withOpacity(0.15),
          backgroundColor: Get.theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (_) => onTap(item),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _appBarBg(context),
        title: Text(
          controller.isEdit.value ? "Edit Listing" : "Sell Item",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      /// 🔥 Sticky Button
      bottomNavigationBar: Obx(
        () => Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: controller.isUploading.value
                ? null
                : controller.uploadListing,
            child: controller.isUploading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    controller.isEdit.value ? "Update Listing" : "Post Ad",
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),

      body: Obx(
        () => SingleChildScrollView(
          // padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// ================= IMAGES =================
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Images", context),

                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...controller.images.asMap().entries.map((entry) {
                            int index = entry.key;
                            String img = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 95,
                                      height: 95,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: img.startsWith("http")
                                              ? NetworkImage(img)
                                              : FileImage(File(img))
                                                    as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () =>
                                          controller.removeImage(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          /// Add Image Button
                          GestureDetector(
                            onTap: controller.pickImage,
                            child: Container(
                              width: 95,
                              height: 95,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.dividerColor,
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(Icons.add, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// ================= CATEGORY =================
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Category", context),
                    chipWrap(
                      items: controller.categories
                          .map((e) => e["name"] as String)
                          .toList(),
                      selected: controller.selectedMain.value,
                      onTap: (val) {
                        controller.selectedMain.value = val;
                        controller.selectedSub.value = "";
                        controller.selectedChild.value = "";
                      },
                    ),

                    /// 🔹 Sub Category
                    if (controller.selectedMain.isNotEmpty) ...[
                      const SizedBox(height: 14),

                      Text(
                        "Sub Category",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),

                      chipWrap(
                        items: controller.subCategories
                            .map((e) => e["name"] as String)
                            .toList(),
                        selected: controller.selectedSub.value,
                        onTap: (val) {
                          controller.selectedSub.value = val;
                          controller.selectedChild.value = "";
                        },
                      ),
                    ],

                    /// 🔹 Type (Child Category)
                    if (controller.childCategories.isNotEmpty) ...[
                      const SizedBox(height: 14),

                      Text(
                        "Type",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      chipWrap(
                        items: controller.childCategories
                            .map<String>((e) => e["name"] as String)
                            .toList(),
                        selected: controller.selectedChild.value,
                        onTap: (val) {
                          controller.selectedChild.value = val;
                        },
                      ),
                    ],
                  ],
                ),
              ),

              /// ================= DETAILS =================
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Details", context),

                    AppTextField(
                      controller: controller.titleController,
                      hintText: "Title",
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: controller.priceController,
                      hintText: "Price",
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: controller.descriptionController,
                      hintText: "Description",
                      maxLines: 4,
                    ),
                  ],
                ),
              ),

              /// ================= CONDITION =================
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Condition", context),
                    chipWrap(
                      items: controller.conditions,
                      selected: controller.selectedCondition.value,
                      onTap: (val) {
                        controller.selectedCondition.value = val;
                      },
                    ),
                  ],
                ),
              ),

              /// ================= LOCATION =================
              sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle("Location", context),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            controller.fullAddress.value.isEmpty
                                ? "No location detected"
                                : controller.fullAddress.value,
                          ),
                        ),
                        TextButton(
                          onPressed: controller.detectLocation,
                          child: controller.isDetectingLocation.value
                              ? const SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Detect"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
