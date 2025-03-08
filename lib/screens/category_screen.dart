import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/category_conroller.dart';
import '../models/category.dart';

import '../models/store_details.dart';
import '../screens/warehouse_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final catController = Get.find<CategoryController>();
  final TextEditingController _searchController = TextEditingController();
  List<Category> filteredCategories = [];

  @override
  void initState() {
    super.initState();
    // Initially, show all categories
    filteredCategories = catController.categories;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredCategories = catController.categories
          .where((category) =>
              category.categoryName.toLowerCase().contains(query) ||
              category.categoryCode.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Image.asset(
          "assets/images/idpgH2alr7_1738673273412.png",
          width: double.infinity,
          height: 50.0,
          color: Colors.white,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Focus on search field when search icon is tapped
              showSearch(
                context: context,
                delegate: CategorySearchDelegate(
                    catController.categories, false, catController),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (catController.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredCategories.isEmpty) {
          return const Center(child: Text("No categories available"));
        }

        return Column(
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Obx(() => catController.storesLoaded.value
                    ? buildStoreSelectionDrobDownMenu(catController)
                    : Center(
                        child: CircularProgressIndicator(),
                      ))),
            Expanded(
              child: GetBuilder<CategoryController>(
                builder: (controller) => ListView.builder(
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, index) {
                    var category = filteredCategories[index];
                    return CustomCategoryCard(
                      category: category,
                      onTap: () async {
                        // Save the selected category for future use
                        await catController.prefs
                            .setString('catCode', category.categoryCode);

                        // Navigate to WarehouseScreen with arguments
                        if (catController.selectedStore.value != null) {
                          Get.off(() => WarehouseScreen());
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  DropdownButtonFormField<StoreData> buildStoreSelectionDrobDownMenu(
      CategoryController catController) {
    return DropdownButtonFormField<StoreData>(
      decoration: const InputDecoration(
        labelText: 'Select Store',
        labelStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      ),
      value: catController.stores.contains(catController.selectedStore.value)
          ? catController.selectedStore.value
          : null,
      onChanged: (StoreData? newValue) {
        if (newValue != null) {
          catController.updateSelectedValue(newValue);
        }
      },
      items: catController.stores
          .toSet()
          .map<DropdownMenuItem<StoreData>>((StoreData store) {
        return DropdownMenuItem<StoreData>(
          value: store,
          child: Text(
            store.name,
            style: const TextStyle(fontSize: 16.0),
          ),
        );
      }).toList(),
      isExpanded: true,
      iconSize: 24.0,
      iconEnabledColor: Colors.black,
    );
  }
}

// Custom Category Card Widget
class CustomCategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CustomCategoryCard(
      {super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0, // Shadow for Card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners for card
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        title: Text(
          category.categoryName,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Improved readability
          ),
        ),
        subtitle: Text(
          category.categoryCode,
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.grey.shade500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class CategorySearchDelegate extends SearchDelegate {
  final CategoryController _categoryController;
  final List<Category> categories;
  bool isSearching;

  CategorySearchDelegate(
      this.categories, this.isSearching, this._categoryController);

  @override
  List<Widget> buildActions(BuildContext context) {
    isSearching = true;
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (query.isEmpty) {
          close(context, null); // Close search when no text is entered
        } else {
          query = ''; // Clear search input if something is typed
        }
      },
      icon: Icon(Icons.arrow_back, color: Colors.black),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<Category> results = categories
        .where((category) =>
            category.categoryName.toLowerCase().contains(query.toLowerCase()) ||
            category.categoryCode.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        var category = results[index];
        return CustomCategoryCard(
          category: category,
          onTap: () async {
            // Save the selected category for future use
            await _categoryController.prefs.setString(
              'catCode',
              category.categoryCode,
            );

            // Navigate to WarehouseScreen with arguments
            if (_categoryController.selectedStore.value != null &&
                query.isNotEmpty) {
              Get.off(() => WarehouseScreen());
            }
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<Category> suggestions = categories
        .where((category) =>
            category.categoryName.toLowerCase().contains(query.toLowerCase()) ||
            category.categoryCode.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        var category = suggestions[index];
        return CustomCategoryCard(
          category: category,
          onTap: () async {
            // Save the selected category for future use
            await Get.find<CategoryController>().prefs.setString(
                  'catCode',
                  category.categoryCode,
                );

            // Navigate to WarehouseScreen with arguments
            isSearching = false;
            Get.off(() => WarehouseScreen());
          },
        );
      },
    );
  }
}
