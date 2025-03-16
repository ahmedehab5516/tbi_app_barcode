import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sub_category_screen.dart';
import '../widgets/loading_indecator.dart';

import '../controllers/category_conroller.dart';
import '../models/category.dart';

import '../models/store_details.dart';

class ParentCategoryScreen extends StatefulWidget {
  const ParentCategoryScreen({super.key});

  @override
  _ParentCategoryScreenState createState() => _ParentCategoryScreenState();
}

class _ParentCategoryScreenState extends State<ParentCategoryScreen> {
  final catController = Get.find<CategoryController>();
  final TextEditingController _searchController = TextEditingController();
  List<Category> filteredCategories = [];

  @override
  void initState() {
    super.initState();
    // Initially, show all categories
    filteredCategories = catController.parentCategories;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredCategories = catController.parentCategories
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
                    catController.parentCategories, catController),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (catController.loading.value) {
          return const Center(child: BuildLoadingIndecator());
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
                        // Normal list onTap callback in ParentCategoryScreen
                        onTap: () async {
                          if (catController.selectedStore.value == null) {
                            Get.snackbar("Store Not Selected",
                                "Please choose a store before selecting a category.",
                                backgroundColor: Colors.red,
                                colorText: Colors.white);
                            return;
                          }
                          // Save the selected category for future use
                          await catController.prefs.setString(
                            'parentCat',
                            jsonEncode(category.toJson()),
                          );
                          // Clear the previous child categories before fetching new ones.
                          catController.childCategories.clear();
                          // Fetch children for the newly selected parent category.
                          await catController
                              .fetchChildCategories(category.categoryCode);
                          Get.to(() => ChildCategoryScreen());
                        });
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

  CategorySearchDelegate(this.categories, this._categoryController);

  @override
  List<Widget> buildActions(BuildContext context) {
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
        onPressed: () => Get.back(), icon: Icon(Icons.arrow_back));
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
            if (_categoryController.selectedStore.value == null) {
              Get.snackbar("Store Not Selected",
                  "Please choose a store before selecting a category.",
                  backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            await _categoryController.prefs.setString(
              'parentCat',
              jsonEncode(category.toJson()),
            );
            // Clear the previous child categories before fetching new ones.
            _categoryController.childCategories.clear();
            // Fetch children for the newly selected parent category.
            await _categoryController
                .fetchChildCategories(category.categoryCode);
            Get.to(() => ChildCategoryScreen());
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
        Category category = suggestions[index];
        return CustomCategoryCard(
          category: category,
          onTap: () async {
            if (_categoryController.selectedStore.value == null) {
              Get.snackbar("Store Not Selected",
                  "Please choose a store before selecting a category.",
                  backgroundColor: Colors.red, colorText: Colors.white);
              return;
            }
            await _categoryController.prefs.setString(
              'parentCat',
              jsonEncode(category.toJson()),
            );
            // Clear the previous child categories before fetching new ones.
            _categoryController.childCategories.clear();
            // Fetch children for the newly selected parent category.
            await _categoryController
                .fetchChildCategories(category.categoryCode);
            Get.to(() => ChildCategoryScreen());
          },
        );
      },
    );
  }
}
