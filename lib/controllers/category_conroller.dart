import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/auth_gate.dart';
import '../common_files/snack_bar.dart';
import '../models/category.dart';
import 'package:http/http.dart' as http;
import '../models/product_data.dart';
import 'base_controller.dart'; // Import GetX for reactive programming

class CategoryController extends BaseController {
  late Rx<TextEditingController> stockIdController;
  RxBool showCategories = false.obs;
  RxBool loading = false.obs; // Track loading state
  List<Category> categories = [];
  final String _baseUrl = "https://visa-api.ck-report.online/api/Store";

  @override
  void onInit() {
    super.onInit();
    stockIdController = Rx<TextEditingController>(TextEditingController());

    _loadStockingId(); // Load the saved stocking ID if available
  }

  // Save stocking ID to SharedPreferences
  Future<void> _saveStockingId(String stockId) async {
    prefs.setString("stocking_id", stockId);
  }

  // Load stocking ID from SharedPreferences
  Future<void> _loadStockingId() async {
    String? stockId = prefs.getString("stocking_id");
    

    if (stockId != null) {
      // If the stock ID exists, load it and fetch categories
      stockIdController.value.text = stockId;
      showCategories.value = true;
      fetchCategories(); // Fetch categories when stock ID is already saved
    } else {
      // Otherwise, set showCategories to false
      showCategories.value = false;
    }

    loading.value = false; // Stop loading after checking for stock ID
  }

  // Clear the stocking ID when "End Stocking" is pressed
  Future<void> clearStockingId() async {
    prefs.remove("stocking_id"); // Remove the stored stocking ID
    stockIdController.value.clear(); // Clear the controller
    showCategories.value = false; // Hide categories
    Get.off(() => AuthGate());
    update(); // Update the UI
  }

  @override
  void onClose() {
    stockIdController.value.dispose(); // Dispose of the TextEditingController
    super.onClose();
  }

  /// Fetch categories from the API
  Future<void> fetchCategories() async {
    loading.value = true; // Start loading when fetching categories
    try {
      final response = await http.get(Uri.parse("$_baseUrl/loadCategories"));

      if (response.statusCode == 200) {
        final categoryResponse =
            CategoryResponse.fromJson(jsonDecode(response.body));
        if (categoryResponse.status == 1) {
          categories.clear();
          categories.addAll(categoryResponse.data);
          update();
          showCategories.value = categories.isNotEmpty;
        } else {
          showCategories.value = false;
          SnackbarHelper.showFailure("Error", "No categories available.");
        }
      } else {
        showCategories.value = false;
        SnackbarHelper.showFailure("Error", "Failed to fetch categories.");
      }
    } catch (e) {
      showCategories.value = false;
      SnackbarHelper.showFailure(
          "Error", "Failed to load categories: ${e.toString()}");
    } finally {
      loading.value = false; // Stop loading when done
    }
  }

  // Method to check the stock ID validation and fetch categories
  void checkStockIdValidation() async {
    if (stockIdController.value.text.isNotEmpty) {
      loading.value = true; // Start loading
      try {
        // Save the stock ID to SharedPreferences
        await _saveStockingId(stockIdController.value.text);

        // Fetch categories after saving the stock ID
        await fetchCategories();
      } catch (e) {
        SnackbarHelper.showFailure(
            "Error", "Failed to validate stock ID: ${e.toString()}");
      } finally {
        loading.value = false; // Stop loading
      }
    } else {
      SnackbarHelper.showFailure(
          "Validation Error", "Stock ID cannot be empty.");
    }
  }
}
