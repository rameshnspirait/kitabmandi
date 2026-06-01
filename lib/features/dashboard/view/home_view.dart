import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kitab_mandi/core/constants/app_color.dart';
import 'package:kitab_mandi/core/controller/filter_controller.dart';
import 'package:kitab_mandi/core/controller/location_controller.dart';
import 'package:kitab_mandi/features/dashboard/controller/home_controller.dart';
import 'package:kitab_mandi/features/dashboard/widget/home_listing_card_shimmer.dart';
import 'package:kitab_mandi/features/dashboard/widget/home_listing_card_widget.dart';
import 'package:kitab_mandi/features/dashboard/widget/home_location_appbar_widget.dart';
import 'package:kitab_mandi/widgets/app_cached_image_network.dart';
import 'package:shimmer/shimmer.dart';

class HomeView extends StatelessWidget {
  HomeView({super.key}) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await rootBundle.loadString('assets/data/categories.json');
    final decoded = json.decode(data);
    categoriesData.value = decoded['categories'];
  }

  final homeCtrl = Get.put(HomeController());
  final filterCtrl = Get.put(FilterController());
  final locationCtrl = Get.find<LocationController>();
  final RxInt currentBanner = 0.obs;
  final RxList categoriesData = [].obs;

  IconData getIcon(String name) {
    switch (name.toLowerCase()) {
      case "book":
        return Icons.menu_book_rounded;
      case "school":
        return Icons.school_rounded;
      case "academic":
        return Icons.auto_stories_rounded;
      case "trophy":
        return Icons.workspace_premium_rounded;
      case "note":
        return Icons.sticky_note_2_rounded;
      case "pen":
        return Icons.draw_rounded;
      case "laptop":
        return Icons.laptop_mac_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  final List<Map<String, String>> bannerList = [
    {
      "title": "Buy & sell\nbooks easily\nnear you",
      "url": "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f",
    },
    {
      "title": "Affordable study\nmaterials for\nevery student",
      "url": "https://images.unsplash.com/photo-1512820790803-83ca734da794",
    },
    {
      "title": "Upgrade your\nlearning with\nsecond-hand books",
      "url": "https://images.unsplash.com/photo-1516979187457-637abb4f9353",
    },
  ];

  double responsiveText(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1000) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= 600) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  void _openLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LocationSheet(),
    );
  }

  Color _background(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1A1D23) : const Color(0xFFFFFFFF);
  }

  Color _border(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.transparent : const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final width = MediaQuery.of(context).size.width;

    final bool isTablet = width > 600;

    final bool isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF090B13) : const Color(0xFFF7F8FA);

    final cardColor = isDark ? const Color(0xFF171B22) : Colors.white;

    final primaryText = isDark ? Colors.white : const Color(0xFF111827);

    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background(context),
        shape: Border(bottom: BorderSide(color: _border(context), width: 1)),
        titleSpacing: 12,
        title: Row(
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),

            const SizedBox(width: 8),

            /// FIXED OVERFLOW
            Expanded(
              child: Obx(() {
                return GestureDetector(
                  onTap: () => _openLocationSheet(context),

                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          locationCtrl.selectedLocations.isEmpty
                              ? "Select Location"
                              : locationCtrl.selectedLocations.join(", "),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),

                      const SizedBox(width: 2),

                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: theme.iconTheme.color,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          homeCtrl.fetchTopViewedListings();
        },

        child: Obx(() {
          /// ================= LOADING =================
          if (homeCtrl.isLoading.value) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 120),

              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  height: isTablet ? 240 : 190,

                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(28),

                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.25)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 115,

                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,

                    itemBuilder: (_, __) {
                      return Container(
                        width: 80,

                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),

                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      );
                    },

                    separatorBuilder: (_, __) => const SizedBox(width: 16),

                    itemCount: 5,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 320,

                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,

                    itemBuilder: (_, __) => const SizedBox(
                      width: 210,
                      child: ListingGridCardShimmer(),
                    ),

                    separatorBuilder: (_, __) => const SizedBox(width: 16),

                    itemCount: 4,
                  ),
                ),
              ],
            );
          }

          /// ================= MAIN UI =================
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),

            children: [
              const SizedBox(height: 8),

              /// ================= BANNER =================
              CarouselSlider.builder(
                itemCount: bannerList.length,
                options: CarouselOptions(
                  height: isTablet ? 260 : 190,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: isTablet ? 0.75 : 0.92,
                  autoPlayInterval: const Duration(seconds: 4),

                  onPageChanged: (index, reason) {
                    currentBanner.value = index;
                  },
                ),

                itemBuilder: (_, index, realIndex) {
                  return Container(
                    width: double.infinity,

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),

                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,

                        colors: [Color(0xFFEAF8E7), Color(0xFFD8EFD3)],
                      ),
                    ),

                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),

                      child: Stack(
                        children: [
                          /// LEFT CONTENT
                          Positioned(
                            left: 18,
                            top: 18,
                            bottom: 18,

                            child: SizedBox(
                              width: width * 0.38,

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Text(
                                    bannerList[index]["title"]!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,

                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: responsiveText(
                                        context,
                                        mobile: 18,
                                        tablet: 24,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      letterSpacing: -0.5,
                                      color: Colors.black,
                                    ),
                                  ),

                                  SizedBox(height: isTablet ? 14 : 10),

                                  Text(
                                    "Buy & Sell Books, Notes\nwith nearby students",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: responsiveText(
                                        context,
                                        mobile: 11,
                                        tablet: 14,
                                      ),
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black.withOpacity(0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          /// RIGHT IMAGE
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,

                            child: SizedBox(
                              width: width * 0.42,

                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(28),
                                  bottomRight: Radius.circular(28),
                                ),

                                child: AppCachedImageNetwork(
                                  imageUrl: bannerList[index]["url"]!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              /// ================= DOTS =================
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(bannerList.length, (index) {
                    final isActive = currentBanner.value == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 7,
                      width: isActive ? 12 : 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: isActive
                            ? theme.colorScheme.primary
                            : isDark
                            ? Colors.white24
                            : Colors.black12,
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 10),

              /// ================= CATEGORY HEADER =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      "Top Categories",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: responsiveText(
                          context,
                          mobile: 16,
                          tablet: 24,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: primaryText,
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Get.to(() => AllCategoriesScreen());
                      },

                      child: Text(
                        "See all",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: responsiveText(
                            context,
                            mobile: 12,
                            tablet: 15,
                          ),
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// ================= CATEGORY LIST =================
              Obx(() {
                if (categoriesData.isEmpty) {
                  return const SizedBox();
                }

                return SizedBox(
                  height: isTablet ? 120 : 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: 8,
                    itemBuilder: (_, index) {
                      final category = categoriesData[index];
                      return GestureDetector(
                        onTap: () {
                          Get.to(
                            () => AllCategoriesScreen(initialIndex: index),
                          );
                        },
                        child: SizedBox(
                          width: isTablet ? 96 : 78,
                          child: Column(
                            children: [
                              Container(
                                width: isTablet ? 72 : 62,
                                height: isTablet ? 72 : 62,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  color: cardColor,
                                  border: Border.all(color: borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.25)
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  getIcon(category['icon']),
                                  size: isTablet ? 30 : 24,
                                  color: theme.colorScheme.primary,
                                ),
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                height: 34,
                                child: Center(
                                  child: Text(
                                    category['name'],
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: responsiveText(
                                        context,
                                        mobile: 11,
                                        tablet: 12.5,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

              const SizedBox(height: 20),

              /// ================= POPULAR HEADER =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular Near You",

                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: responsiveText(
                          context,
                          mobile: 16,
                          tablet: 24,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: primaryText,
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Get.to(() => AllListingsScreen());
                      },

                      child: Text(
                        "See all",

                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: responsiveText(
                            context,
                            mobile: 12,
                            tablet: 15,
                          ),
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              /// ================= LISTINGS =================
              SizedBox(
                height: isTablet ? 360 : 295,
                child: Obx(() {
                  /// 🔄 If location still loading
                  if (locationCtrl.isLoadingLocation.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  /// 📍 If location not available
                  if (locationCtrl.latitude.value == 0.0 ||
                      locationCtrl.longitude.value == 0.0) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          "Location not detected",
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () async {
                            await locationCtrl.detectCurrentLocation();
                          },
                          child: const Text("Detect Location"),
                        ),
                      ],
                    );
                  }

                  /// 📦 No listings in 5KM
                  if (homeCtrl.popularListingNearYou.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          "No items found within 5 KM",
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Try changing location or increasing radius",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    );
                  }

                  /// ✅ DATA FOUND
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemCount: homeCtrl.popularListingNearYou.length,
                    itemBuilder: (_, index) {
                      final book = homeCtrl.popularListingNearYou[index];
                      return SizedBox(
                        width: isTablet ? 250 : 190,
                        child: ListingGridCard(listingModel: book),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LocationSheet extends StatelessWidget {
  const _LocationSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<LocationController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),

              /// HANDLE
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),

              /// HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      "Location",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              /// 📍 CURRENT LOCATION
              Obx(() {
                return ListTile(
                  leading: controller.isLoadingLocation.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.my_location,
                          color: theme.colorScheme.primary,
                        ),
                  title: Text(
                    controller.isLoadingLocation.value
                        ? "Detecting location..."
                        : "Use current location",
                  ),
                  onTap: () async {
                    await controller.detectCurrentLocation();
                    Get.back();
                  },
                );
              }),

              const Divider(),

              ///  RECENT LOCATIONS
              Obx(() {
                if (controller.recentLocations.isEmpty) {
                  return const SizedBox();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Recent Locations",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    ...controller.recentLocations.map((loc) {
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(loc),
                        onTap: () {
                          controller.updateLocation(loc);
                          Get.back();
                        },
                      );
                    }),
                    const Divider(),
                  ],
                );
              }),

              // /// 📍 STATES LIST
              // Expanded(
              //   child: ListView.builder(
              //     controller: scrollController,
              //     itemCount: states.length,
              //     itemBuilder: (_, i) {
              //       final state = states[i];
              //       return ListTile(
              //         // leading: const Icon(Icons.map),
              //         title: Text(state),
              //         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              //         onTap: () {
              //           Get.to(
              //             () => CityScreen(
              //               state: state,
              //               cities: stateCities[state]!,
              //             ),
              //           );
              //         },
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }
}

class AllCategoriesScreen extends StatefulWidget {
  final int initialIndex;

  const AllCategoriesScreen({super.key, this.initialIndex = 0});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  List categories = [];

  final filterCtrl = Get.find<FilterController>();
  final homeCtrl = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await rootBundle.loadString('assets/data/categories.json');
    final decoded = json.decode(data);

    final loadedCategories = decoded['categories'];

    /// 🔥 DEFAULT SELECTION WHEN COMING FROM "SEE ALL"
    if (filterCtrl.selectedCategory.value.isEmpty &&
        loadedCategories.isNotEmpty) {
      ///  MAIN CATEGORY → FIRST
      filterCtrl.selectedCategory.value = loadedCategories[0]['name'];

      final sub = loadedCategories[0]['subcategories'] ?? [];

      ///  SUB CATEGORY → FIRST
      if (sub.isNotEmpty) {
        filterCtrl.selectedSubCategory.value = sub[0]['name'];
      }

      /// ❌ CHILD → KEEP EMPTY
      filterCtrl.selectedType.value = '';
    }

    setState(() {
      categories = loadedCategories;
    });
  }

  int getMainIndex() {
    final index = categories.indexWhere(
      (c) => c['name'] == filterCtrl.selectedCategory.value,
    );
    return index == -1 ? 0 : index;
  }

  int getSubIndex(List subCategories) {
    final index = subCategories.indexWhere(
      (s) => s['name'] == filterCtrl.selectedSubCategory.value,
    );

    return index == -1 ? 0 : index;
  }

  IconData getIcon(String name) {
    switch (name.toLowerCase()) {
      case "book":
        return Icons.menu_book_rounded;
      case "school":
        return Icons.school_rounded;
      case "academic":
        return Icons.auto_stories_rounded;
      case "trophy":
        return Icons.workspace_premium_rounded;
      case "note":
        return Icons.sticky_note_2_rounded;
      case "pen":
        return Icons.draw_rounded;
      case "laptop":
        return Icons.laptop_mac_rounded;
      case "exam":
        return Icons.fact_check_rounded;
      case "science":
        return Icons.science_rounded;
      case "math":
        return Icons.calculate_rounded;
      case "language":
        return Icons.translate_rounded;
      case "commerce":
        return Icons.account_balance_rounded;
      case "engineering":
        return Icons.engineering_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void applyAndNavigate() {
    homeCtrl.applyAllFilters();
    Get.to(() => AllListingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Obx(() {
      final selectedMainIndex = getMainIndex();
      final main = categories[selectedMainIndex];

      final subCategories = main['subcategories'] ?? [];
      final selectedSubIndex = subCategories.isEmpty
          ? 0
          : getSubIndex(subCategories);

      final selectedSub = subCategories.isNotEmpty
          ? subCategories[selectedSubIndex]
          : null;

      final children = selectedSub != null
          ? (selectedSub['children'] ?? [])
          : [];

      return Scaffold(
        appBar: AppBar(title: const Text("Categories")),

        body: Row(
          children: [
            /// LEFT PANEL
            Container(
              width: 90,
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (_, index) {
                  final item = categories[index];
                  final isSelected =
                      filterCtrl.selectedCategory.value == item['name'];

                  return GestureDetector(
                    onTap: () {
                      filterCtrl.selectedCategory.value = item['name'];
                      filterCtrl.selectedSubCategory.value = '';
                      filterCtrl.selectedType.value = '';

                      final sub = item['subcategories'] ?? [];

                      /// 🔥 NO SUB → APPLY
                      if (sub.isEmpty) {
                        applyAndNavigate();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      child: Column(
                        children: [
                          Icon(
                            getIcon(item['icon']),
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black,
                          ),
                          Text(
                            item['name'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// RIGHT PANEL
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    /// SUB CATEGORY
                    SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: subCategories.length,
                        itemBuilder: (_, index) {
                          final sub = subCategories[index];
                          final isSelected =
                              filterCtrl.selectedSubCategory.value ==
                              sub['name'];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(sub['name']),
                              selected: isSelected,
                              onSelected: (_) {
                                filterCtrl.selectedSubCategory.value =
                                    sub['name'];
                                filterCtrl.selectedType.value = '';

                                final children = sub['children'] ?? [];

                                /// 🔥 NO CHILD → APPLY
                                if (children.isEmpty) {
                                  applyAndNavigate();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CHILD GRID
                    Expanded(
                      child: GridView.builder(
                        itemCount: children.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2,
                            ),
                        itemBuilder: (_, index) {
                          final item = children[index];
                          final isSelected =
                              filterCtrl.selectedType.value == item['name'];

                          return GestureDetector(
                            onTap: () {
                              filterCtrl.selectedType.value = item['name'];

                              /// 🔥 APPLY + NAVIGATE
                              applyAndNavigate();
                            },
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  item['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class AllListingsScreen extends StatelessWidget {
  AllListingsScreen({super.key});

  final homeCtrl = Get.find<HomeController>();
  final filterCtrl = Get.find<FilterController>();

  double responsiveText(
    BuildContext context, {
    required double mobile,
    double? tablet,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width > 600) {
      return tablet ?? mobile;
    }

    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF090B13) : const Color(0xFFF7F8FA);

    final cardColor = isDark ? const Color(0xFF171B22) : Colors.white;

    final primaryText = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: LocationAppBar(),

      body: Obx(() {
        /// ================= SHIMMER =================
        if (homeCtrl.isLoading.value) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),

            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 300,
            ),

            itemCount: 6,

            itemBuilder: (_, __) {
              return _ListingShimmerCard(isDark: isDark, cardColor: cardColor);
            },
          );
        }

        return Obx(
          () => RefreshIndicator(
            color: Colors.green,
            backgroundColor: isDark ? const Color(0xFF171B22) : Colors.white,

            onRefresh: () async {
              await homeCtrl.fetchAllListings();

              /// 🔥 IMPORTANT
              homeCtrl.applyAllFilters();
            },

            child: homeCtrl.filteredListings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: Get.height * 0.35),

                      Center(
                        child: Text(
                          "No Listings Found 😔",
                          style: TextStyle(
                            color: primaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: responsiveText(
                              context,
                              mobile: 16,
                              tablet: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      int crossAxisCount = 2;

                      if (width >= 1200) {
                        crossAxisCount = 5;
                      } else if (width >= 900) {
                        crossAxisCount = 4;
                      } else if (width >= 600) {
                        crossAxisCount = 3;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),

                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: width >= 600 ? 320 : 300,
                        ),

                        /// ✅ USE FILTERED LIST
                        itemCount: homeCtrl.filteredListings.length,

                        itemBuilder: (_, index) {
                          final book = homeCtrl.filteredListings[index];

                          return SizedBox(
                            width: double.infinity,
                            child: ListingGridCard(listingModel: book),
                          );
                        },
                      );
                    },
                  ),
          ),
        );
      }),
    );
  }
}

/// ================= SHIMMER CARD =================

class _ListingShimmerCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;

  const _ListingShimmerCard({required this.isDark, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,

      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,

      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// IMAGE
            Container(
              height: 170,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 12),

                  Container(height: 12, width: 120, color: Colors.white),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Container(height: 12, width: 70, color: Colors.white),

                      const Spacer(),

                      Container(height: 12, width: 50, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
