import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/category_conroller.dart';
import '../controllers/register_controller.dart';
import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import '../screens/warehouse_screen.dart';
import '../models/store_details.dart';

class CategoryScreen extends StatelessWidget {
  CategoryScreen({super.key});
  final catController = Get.find<CategoryController>();

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
      ),
      body: Obx(() {
        if (catController.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!catController.showCategories.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "You need to enter a stock ID to start stocking",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  MyTextField(
                    hintText: "Stock ID",
                    controller: catController.stockIdController.value,
                    onChanged: (value) {
                      catController.update();
                    },
                  ),
                  // Store Selection Dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    child: Obx(() {
                      if (!catController.storesLoaded.value) {
                        return const CircularProgressIndicator();
                      }

                      return DropdownButtonFormField<StoreData>(
                        decoration: const InputDecoration(
                          labelText: 'Select Store',
                          labelStyle: TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 14.0),
                        ),
                        value: catController.selectedStore.value,
                        onChanged: (StoreData? newValue) {
                          if (newValue != null) {
                            catController.updateSelectedValue(newValue);
                          }
                        },
                        items: catController.stores
                            .map<DropdownMenuItem<StoreData>>(
                                (StoreData store) {
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
                    }),
                  ),
                  const SizedBox(height: 20),
                  GetBuilder<CategoryController>(
                    builder: (controller) => MyButton(
                      onTap: () => catController.checkStockIdValidation(),
                      label: "Show Categories",
                      backgroundColor:
                          catController.stockIdController.value.text.isEmpty
                              ? Colors.grey
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

    
        // Dropdown for store selection
        return Column(
          children: [
            // Show Categories List after Stock ID Validation
            Expanded(
              child: GetBuilder<CategoryController>(
                builder: (controller) => ListView.builder(
                  itemCount: catController.categories.length,
                  itemBuilder: (context, index) {
                    var category = catController.categories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      elevation: 4.0, // Shadow for Card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            12.0), // Rounded corners for card
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal:
                                16.0), // Smaller padding to reduce height
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.categoryName,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87, // Improved readability
                              ),
                            ),
                            Text(
                              category.categoryCode,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors
                                    .grey, // Lighter text color for category code
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Save the selected category for future use
                          catController.prefs.setString(
                            'catCode',
                            category.categoryCode,
                          );
                          print(catController.selectedStore.value!.id);
                          Get.off(() => WarehouseScreen(), arguments: {
                            "catCode": category.categoryCode,
                            "sid": catController.stockIdController.value.text,
                            "store": catController.selectedStore.value
                          });
                        },
                      ),
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
