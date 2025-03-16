import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/loading_indecator.dart';

import '../controllers/category_conroller.dart';
import '../models/category.dart';
import '../screens/warehouse_screen.dart';

class ChildCategoryScreen extends StatefulWidget {
  const ChildCategoryScreen({super.key});

  @override
  _ChildCategoryScreenState createState() => _ChildCategoryScreenState();
}

class _ChildCategoryScreenState extends State<ChildCategoryScreen> {
  final catController = Get.find<CategoryController>();

  // Initially, filteredCategories shows all child categories.

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (controller) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          leading: IconButton(
              onPressed: () => Get.back(), icon: Icon(Icons.arrow_back)),
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
                showSearch(
                  context: context,
                  delegate: CategorySearchDelegate(catController),
                );
              },
            ),
          ],
        ),
        body: Obx(() {
          if (catController.loading.value) {
            return const Center(child: BuildLoadingIndecator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: catController.childCategories.length,
                  itemBuilder: (context, index) {
                    var category = catController.childCategories[index];
                    return BuildChildCategoryCard(
                      category: category,
                      catController: catController,
                      onTap: () async {
                        // Save the selected child category for future use.
                        await catController.prefs.setString(
                            'childCat', jsonEncode(category.toJson()));

                        // Navigate to WarehouseScreen if a store is selected.
                        if (catController.selectedStore.value != null) {
                          Get.off(() => WarehouseScreen());
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// A reusable widget for displaying a child category.
/// Accepts an optional onTap callback.
class BuildChildCategoryCard extends StatelessWidget {
  final Category category;
  final CategoryController catController;
  final VoidCallback? onTap;

  const BuildChildCategoryCard({
    super.key,
    required this.category,
    required this.catController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        title: Text(
          category.categoryName,
          style: const TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          category.categoryCode,
          style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
        ),
        onTap: onTap ??
            () async {
              // Default action if no onTap provided.
              await catController.prefs
                  .setString('childCat', jsonEncode(category.toJson()));
              if (catController.selectedStore.value != null) {
                Get.off(() => WarehouseScreen());
              }
            },
      ),
    );
  }
}

class CategorySearchDelegate extends SearchDelegate {
  final CategoryController catController;

  CategorySearchDelegate(this.catController);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = catController.childCategories.where((category) {
      return category.categoryName
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          category.categoryCode.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        var category = results[index];
        return BuildChildCategoryCard(
          category: category,
          catController: catController,
          onTap: () async {
            await catController.prefs
                .setString('childCat', jsonEncode(category.toJson()));
            if (catController.selectedStore.value != null) {
              close(context, null);
              Get.off(() => WarehouseScreen());
            }
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = catController.childCategories.where((category) {
      return category.categoryName
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          category.categoryCode.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        var category = suggestions[index];
        return BuildChildCategoryCard(
          category: category,
          catController: catController,
          onTap: () async {
            await catController.prefs
                .setString('childCat', jsonEncode(category.toJson()));
            if (catController.selectedStore.value != null) {
              close(context, null);
              Get.off(() => WarehouseScreen());
            }
          },
        );
      },
    );
  }
}
