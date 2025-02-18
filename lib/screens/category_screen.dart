import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/warehouse_controller.dart';
import 'warehouse_screen.dart';

import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import '../controllers/category_conroller.dart';

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
      body: Obx(
        () {
          // Show categories after stock ID is valid and loading is done
          if (catController.loading.value) {
            return const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            );
          }

          // If showCategories is false, show Stock ID input and button
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
                      onChanged: (value){
                        catController.update();
                      },
                      
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

          // Show categories after stock ID is valid
          return Column(
            children: [
              Expanded(
                child: GetBuilder<CategoryController>(
                  builder: (controller) => ListView.builder(
                    itemCount: catController.categories.length,
                    itemBuilder: (context, index) {
                      var category = catController.categories[index];
                      return ListTile(
                        title: Text(category.categoryName),
                        subtitle: Text(category.categoryCode),
                        onTap: () {
                          // Pass category and stockId when navigating to WarehouseScreen
                          Get.off(() => WarehouseScreen(), arguments: {
                            "catCode": category.categoryCode,
                            "sid": catController.stockIdController.value.text
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
