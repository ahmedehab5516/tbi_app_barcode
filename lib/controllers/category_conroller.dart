import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common_files/snack_bar.dart';
import '../models/category.dart';
import '../models/store_details.dart';
import '../screens/auth_gate.dart';
import 'base_controller.dart'; // Import GetX for reactive programming

class CategoryController extends BaseController {
  // Reactive variables for UI state
  RxBool showParentCategories = false.obs;
  RxBool showChildCategories = false.obs;
  RxBool loading = false.obs;
  
  // Observable lists for categories
  RxList<Category> parentCategories = <Category>[].obs;
  RxList<Category> childCategories = <Category>[].obs;
  
  final String _baseUrl = "https://visa-api.ck-report.online/api/Store";

  // Store management variables
  final RxBool storesLoaded = false.obs;
  Rx<StoreData?> selectedStore = Rx<StoreData?>(null);
  final stores = <StoreData>[].obs;

  @override
  void onInit() async {
    super.onInit();

    // Initialize SharedPreferences
    prefs = Get.find<SharedPreferences>();

    // Fetch parent categories, stores, and the selected store
    await fetchParentCategories();
    await getAllStores();
    await _loadSelectedStore();
  }

  // Update the selected store and save to SharedPreferences
  void updateSelectedValue(StoreData store) {
    selectedStore.value = store;
    _saveSelectedStore(store);
    update();
  }

  Future<void> getAllStores() async {
    final Uri url = Uri.parse("$_baseUrl/loadStores");

    try {
      storesLoaded.value = false;
      final response = await http.get(url);

      if (response.statusCode == 200) {
        StoreDetails loadStores = StoreDetails.fromJson(jsonDecode(response.body));
        stores.clear();
        for (var store in loadStores.data) {
          stores.add(StoreData(id: store.id, name: store.name));
        }
        storesLoaded.value = true;
      } else {
        storesLoaded.value = false;
        throw Exception("Failed to load stores. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      storesLoaded.value = false;
      throw Exception("Error fetching stores: $e");
    }
  }

  // Clear the stocking ID when "End Stocking" is pressed
  Future<void> clearStockingId() async {
    prefs.remove("stocking_id"); // Remove the stored stocking ID

    // Hide categories on clear
    showParentCategories.value = false;
    showChildCategories.value = false;

    await _removeSelectedStore(); // Remove the store from cache
    selectedStore.value = null; // Clear the selected store in memory
    Get.off(() => AuthGate());
    update(); // Update the UI
  }

  // Fetch parent categories (without a Parent query parameter)
  Future<void> fetchParentCategories() async {
    loading.value = true;
    try {
      final response = await http.get(Uri.parse("$_baseUrl/loadCategories"));
      if (response.statusCode == 200) {
        final categoryResponse = CategoryResponse.fromJson(jsonDecode(response.body));
        if (categoryResponse.status == 1) {
          parentCategories.clear();
          parentCategories.addAll(categoryResponse.data);
          update();
          showParentCategories.value = parentCategories.isNotEmpty;
        } else {
          showParentCategories.value = false;
          SnackbarHelper.showFailure("Error", "No parent categories available.");
        }
      } else {
        showParentCategories.value = false;
        SnackbarHelper.showFailure("Error", "Failed to fetch parent categories.");
      }
    } catch (e) {
      showParentCategories.value = false;
      SnackbarHelper.showFailure("Error", "Failed to load parent categories: ${e.toString()}");
    } finally {
      loading.value = false;
    }
  }

  // Fetch child categories based on the selected parent's code
  Future<void> fetchChildCategories(String parentCode) async {
    loading.value = true;
    try {
      final response = await http.get(Uri.parse("$_baseUrl/loadCategories?Parent=$parentCode"));
      if (response.statusCode == 200) {
        final categoryResponse = CategoryResponse.fromJson(jsonDecode(response.body));
        if (categoryResponse.status == 1) {
          childCategories.clear();
          childCategories.addAll(categoryResponse.data);
          update();
          showChildCategories.value = childCategories.isNotEmpty;
        } else {
          showChildCategories.value = false;
          SnackbarHelper.showFailure("Error", "No child categories available.");
        }
      } else {
        showChildCategories.value = false;
        SnackbarHelper.showFailure("Error", "Failed to fetch child categories.");
      }
    } catch (e) {
      showChildCategories.value = false;
      SnackbarHelper.showFailure("Error", "Failed to load child categories: ${e.toString()}");
    } finally {
      loading.value = false;
    }
  }

  // Save the selected store to cache (SharedPreferences)
  Future<void> _saveSelectedStore(StoreData store) async {
    final storeJson = jsonEncode(store.toJson());
    prefs.setString("selected_store", storeJson);
  }

  // Load the selected store from cache (SharedPreferences)
  Future<void> _loadSelectedStore() async {
    final storeJson = prefs.getString("selected_store");
    if (storeJson != null) {
      final storeMap = jsonDecode(storeJson);
      selectedStore.value = StoreData.fromJson(storeMap);
    }
  }

  // Remove the selected store from cache
  Future<void> _removeSelectedStore() async {
    prefs.remove("selected_store");
  }
}
