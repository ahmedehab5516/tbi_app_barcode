import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/category_conroller.dart';
import '../models/category.dart';

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
                delegate: CategorySearchDelegate(catController.categories),
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
                        await catController.prefs.setString(
                          'catCode',
                          category.categoryCode,
                        );

                        // Navigate to WarehouseScreen with arguments
                        Get.off(() => WarehouseScreen());
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
  final List<Category> categories;
  bool isArrowPressed = false; // Keep the state here

  CategorySearchDelegate(this.categories);

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
    return isArrowPressed
        ? SizedBox.shrink()
        : IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              isArrowPressed =
                  true; // Update the state when the back button is pressed
              close(context, null);
            },
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
            await Get.find<CategoryController>().prefs.setString(
                  'catCode',
                  category.categoryCode,
                );

            // Navigate to WarehouseScreen with arguments
            Get.off(() => WarehouseScreen());
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
            Get.off(() => WarehouseScreen());
          },
        );
      },
    );
  }
}
