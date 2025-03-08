import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tbi_app_barcode/screens/register_screen.dart';

import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import '../models/product_data.dart';
import '../models/store_details.dart';
import '../models/warehouse.dart';
import '../other_files/camera_scanner.dart';
import 'base_controller.dart'; // Import GetX for reactive programming
import 'category_conroller.dart';

class WarehouseController extends BaseController {
  // ---------------------------
  // STATE & OBSERVABLES
  // ---------------------------
  final RxString barcode = "".obs;

  final Map<String, TextEditingController> quantityControllers = {};
  // final RxMap<String, int> products = <String, int>{}.obs; // Quantity map
  final RxList<Product> allProducts = <Product>[].obs; // All products
  final RxList<Product> scannedProducts = <Product>[].obs; // Scanned products

  bool showStartButton = true;
  late String categoryCode;

  RxBool loading = false.obs;

  // ---------------------------
  // LIFECYCLE METHODS
  // ---------------------------
  StoreData? storeData; // Changed to nullable
  String? catCode; // Changed to nullable

  @override
  void onInit() async {
    super.onInit();

    // Initialize storeData only if valid JSON is available
    String? storeJson = prefs.getString("selected_store");
    if (storeJson != null && storeJson.isNotEmpty) {
      storeData = StoreData.fromJson(jsonDecode(storeJson));
    } else {
      Get.off(() => RegisterScreen());
    }
    update();

    // Initialize catCode safely
    catCode = prefs.getString("catCode"); // Will be null if not present

    // Start loading state here, before data fetching
    loading.value = true;

    // Ensure that loadProductsInfo finishes before continuing
    allProducts.value = await loadProductsInfo();

    // Once loadProductsInfo finishes, ensure loading is set to false
    loading.value = false;

    await loadCachedProductsData();
  }

//CK- Non Category
  @override
  void onClose() async {
    for (final controller in quantityControllers.values) {
      controller.dispose();
    }
    await saveProductsData();
    super.onClose();
  }

// Retrieve the stocking date from SharedPreferences
  String retrieveStockingDate() {
    return prefs.getString("stocking_date") ?? formatDate(DateTime.now());
  }

  Future<void> saveProductsData() async {
    // Serialize allProducts and scannedProducts lists
    String allProductsJson =
        jsonEncode(allProducts.map((e) => e.toJson()).toList());
    String scannedProductsJson =
        jsonEncode(scannedProducts.map((e) => e.toJson()).toList());

    // Save to SharedPreferences
    await prefs.setString('allProducts', allProductsJson);
    await prefs.setString('scannedProducts', scannedProductsJson);

    // Save showStartButton state
    await prefs.setBool('showStartButton', showStartButton);
    // Convert the storeData object to a JSON string
    String storeDataJson = jsonEncode(storeData!.toJson());

    // Save the JSON string to SharedPreferences
    await prefs.setString('store', storeDataJson);
    await prefs.setString('catCode', catCode!);
    // Log for debugging
  }

  String getProductNameScanned(String barcodeValue) {
    // Look for the product in scannedProducts
    var product = scannedProducts
        .firstWhereOrNull((p) => p.itemLookupCode == barcodeValue);

    // If the product is not found in scannedProducts, search in allProducts
    product ??=
        allProducts.firstWhereOrNull((p) => p.itemLookupCode == barcodeValue);

    // Return the description if found, or "Unregistered Product" if not found
    return product?.description ?? "Unregistered Product";
  }

  String getProductNameAllPro(String barcodeValue, [bool forScanned = false]) {
    final product =
        allProducts.firstWhereOrNull((p) => p.itemLookupCode == barcodeValue);

    // If the product is found, return its description, otherwise return a default message
    return product?.description ?? "Unregistered Product";
  }

  // ---------------------------
  // PRODUCT DATA HANDLING

  Future<List<Product>> loadProductsInfo() async {
    final Uri url = Uri.parse(
        "https://visa-api.ck-report.online/api/Store/loadItems?categoryCode=$catCode");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        allProducts.clear();

        final ProductResponse productsData =
            ProductResponse.fromJson(jsonDecode(response.body));

        update();
        return productsData.data;
      } else {
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load products: ${e.toString()}");
      rethrow;
    } finally {
      // Ensure loading flag is set to false when done
      loading.value = false;
    }
  }

  // ---------------------------
  // CACHING BARCODE DATA
  // ---------------------------
  Future<void> loadCachedProductsData() async {
    // Retrieve saved data from SharedPreferences
    String? allProductsJson = prefs.getString('allProducts');
    String? scannedProductsJson = prefs.getString('scannedProducts');
    bool? savedShowStartButton = prefs.getBool('showStartButton');

    if (allProductsJson != null && scannedProductsJson != null) {
      // Deserialize JSON to list of Product objects
      List<dynamic> allProductsList = jsonDecode(allProductsJson);
      List<dynamic> scannedProductsList = jsonDecode(scannedProductsJson);

      // Convert list to Product objects and add to the respective lists

      allProducts.addAll(
          allProductsList.map((item) => Product.fromJson(item)).toList());
      scannedProducts.addAll(
          scannedProductsList.map((item) => Product.fromJson(item)).toList());

      // If savedShowStartButton exists, restore the showStartButton state
      if (savedShowStartButton != null) {
        showStartButton = savedShowStartButton;
      }

      // Log for debugging

      // Optionally: Ensure TextEditingControllers are initialized after loading
      for (var product in scannedProducts) {
        incrementBarcodeCount(product.itemLookupCode,
            newValue: product.quantity.toString());
        _initializeTextController(
          product.itemLookupCode,
        );
      }
    } else {
      throw ("No saved products data found in SharedPreferences");
    }
  }

  void handleScannerInput(String barcodeValue, BuildContext context) async {
    // Check if the product is already scanned
    Product? existingScannedProduct =
        findProductByBarcode(scannedProducts, barcodeValue);

    if (existingScannedProduct != null) {
      // If already scanned, just update the quantity
      existingScannedProduct.quantity += 1;
      _updateTextController(
          barcodeValue, existingScannedProduct.quantity.toString());
    } else {
      // If not scanned, check if it exists in allProducts
      Product? productInAllProducts =
          findProductByBarcode(allProducts, barcodeValue);

      if (productInAllProducts != null) {
        // If found in allProducts, remove it from there
        allProducts.remove(productInAllProducts);
        productInAllProducts.quantity.value =
            1; // Initialize quantity for scanned products
        scannedProducts.add(productInAllProducts);
        _initializeTextController(
            barcodeValue, productInAllProducts.quantity.toString());
      } else {
        // If not found in allProducts, add as a new unregistered product
        Product newProduct = Product(
          id: "0",
          itemLookupCode: barcodeValue,
          description: "Unregistered Product",
          categoryCode: "unknown",
          categoryName: "unknown",
          quantity: 1,
        );
        scannedProducts.add(newProduct);
        _initializeTextController(barcodeValue, "1");
      }
    }

    update();
    await saveProductsData();
  }

  RxMap<String, RxInt> oldQuantities = <String, RxInt>{}.obs;

  void incrementBarcodeCount(String barcodeValue,
      {int delta = 1, String? newValue}) async {
    final existingProduct = scannedProducts.firstWhereOrNull(
      (p) => p.itemLookupCode == barcodeValue,
    );

    int oldQuantity = existingProduct?.quantity.value ?? 0;
    int newQuantity = oldQuantity;
    int actualDelta = 0;
    // Ensure oldQuantities is initialized for the barcode
    if (!oldQuantities.containsKey(barcodeValue)) {
      oldQuantities[barcodeValue] = RxInt(oldQuantity);
    } else {
      oldQuantities[barcodeValue]!.value = oldQuantity;
    }

    // Handle new value input
    if (newValue != null) {
      newQuantity = int.tryParse(newValue) ?? oldQuantity;
      actualDelta = newQuantity - oldQuantity; // CORRECT DELTA CALCULATION
    } else {
      newQuantity = oldQuantity + delta;
      actualDelta = delta;
    }

    if (existingProduct != null) {
      existingProduct.quantity.value = newQuantity;
      _updateTextController(
          barcodeValue, newQuantity.toString()); // Always show absolute value
    } else if (newQuantity > 0) {
      final newProduct = Product(
        id: "0",
        itemLookupCode: barcodeValue,
        description: getProductNameScanned(barcodeValue),
        categoryCode: "No Category",
        categoryName: "No Category",
        quantity: newQuantity,
      );
      scannedProducts.add(newProduct);
      _initializeTextController(barcodeValue);
    }

    // Send API update only if there's a change
    if (actualDelta != 0) {
      sendStockUpdateToApi(
        barcodeValue,
        actualDelta, // Always send delta (new - old)
      );
    }

    update();
    await saveProductsData();
  }

  void showAddQuantityDialog(String barcodeValue) {
    var quantityController = TextEditingController();
    var additionalQuantity = 0.obs; // Using an observable to react to changes

    Get.dialog(
      AlertDialog(
        title: Text("Add Quantity"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Text(
                "Current Quantity: ${getCurrentQuantity(barcodeValue)}",
                style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(height: 10),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantity to Add",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                additionalQuantity.value = int.tryParse(value) ?? 0;
              },
            ),
            Obx(() => Text(
                "The sum will be: ${getCurrentQuantity(barcodeValue) + additionalQuantity.value}"))
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final addQuantity = additionalQuantity.value;

              if (addQuantity <= 0) {
                Get.snackbar("Error", "Please enter a valid positive number");
                return;
              }

              // Call existing function with the delta to add
              incrementBarcodeCount(
                barcodeValue,
                delta: addQuantity,
              );

              Get.back();
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

// Helper function to get current quantity
  int getCurrentQuantity(String barcodeValue) {
    return scannedProducts
            .firstWhereOrNull(
              (p) => p.itemLookupCode == barcodeValue,
            )
            ?.quantity
            .value ??
        0;
  }

  void sendStockUpdateToApi(String barcode, int delta) {
    final stockUpdate = WarehouseStockProduct(
      barcode: barcode,
      quantity: delta,
      stockDate: retrieveStockingDate(),
      stockingId: "",
      status: 0,
      storeId: storeData!.id,
    );
    sendDataToApi(stockUpdate);
  }

  void _updateTextController(String barcode, String value) {
    quantityControllers[barcode]?.text = value;
  }

// Show the dialog for entering quantity when barcode is new or unregistered
  void _showQuantityDialog(String barcodeValue) {
    TextEditingController quantityController = TextEditingController();

    Get.defaultDialog(
      title: "Enter Quantity",
      content: Column(
        children: [
          Text("Barcode: $barcodeValue",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Enter quantity",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "Confirm",
      textCancel: "Cancel",
      onConfirm: () {
        String enteredQuantity = quantityController.text.trim();
        if (enteredQuantity.isNotEmpty) {
          // Call the method to handle the manual entry logic
          incrementBarcodeCount(barcodeValue, newValue: enteredQuantity);
          _filterProductsLists(barcodeValue, enteredQuantity);
          Get.back(); // Close the dialog

          // Reopen the camera after confirming the quantity
          Future.delayed(Duration(milliseconds: 500), () {
            handleCameraInput();
          });
        } else {
          Get.snackbar("Error", "Please enter a valid quantity!");
        }
      },
    );
  }

// Method to update the product lists: move product to scannedProducts
  void _filterProductsLists(String barcodeValue, String quantity) async {
    int updatedQuantity = int.tryParse(quantity) ?? 1;

    // Find the product in the allProducts list
    Product? manuallyEnteredProduct = allProducts.firstWhereOrNull(
      (product) => product.itemLookupCode == barcodeValue,
    );

    if (manuallyEnteredProduct != null) {
      // Remove product from allProducts first
      allProducts.remove(manuallyEnteredProduct);

      // Create a new instance with updated quantity
      Product updatedProduct = Product(
        id: manuallyEnteredProduct.id,
        itemLookupCode: manuallyEnteredProduct.itemLookupCode,
        description: manuallyEnteredProduct.description,
        categoryCode: manuallyEnteredProduct.categoryCode,
        categoryName: manuallyEnteredProduct.categoryName,
        quantity: updatedQuantity, // Apply the updated quantity here
      );

      // Add the new product instance to scannedProducts
      scannedProducts.add(updatedProduct);
    } else {
      // If the barcode is not in the inventory, add it to the products map
      if (!scannedProducts.any((p) => p.itemLookupCode == barcodeValue)) {
        // Add the unregistered product to scannedProducts with placeholder details
        scannedProducts.add(Product(
          id: "0", // Placeholder ID for unregistered products
          itemLookupCode: barcodeValue,
          description: "Unregistered Product", // Mark as unregistered
          categoryCode: "No Category", // Mark category as unknown
          categoryName: "No Category", // Mark category as unknown
          quantity: updatedQuantity, // The quantity from manual input
        ));
      }
    }

    // Ensure UI updates
    update();

    // Close the bottom sheet or dialog
    Get.back();
    await saveProductsData();
  }

  void updateTextController(String barcode, String value) {
    if (!quantityControllers.containsKey(barcode)) {
      quantityControllers[barcode] = TextEditingController();
    }
    quantityControllers[barcode]!.text = value;
  }

  void _initializeTextController(String barcodeValue, [String? startQuantity]) {
    if (!quantityControllers.containsKey(barcodeValue)) {
      quantityControllers[barcodeValue] = TextEditingController();
    }
    final product = scannedProducts.firstWhereOrNull(
      (p) => p.itemLookupCode == barcodeValue,
    );
    if (product != null) {
      quantityControllers[barcodeValue]!.text =
          startQuantity ?? product.quantity.value.toString();
    }
  }

  void addOrUpdateProduct(String barcodeValue, int quantity) async {
    Product? existingProduct =
        findProductByBarcode(scannedProducts, barcodeValue);

    if (existingProduct != null) {
      // Update the existing product quantity
      existingProduct.quantity +=
          quantity; // Adjust this if you need exact quantity replacement
      updateTextController(barcodeValue, existingProduct.quantity.toString());

      if (!oldQuantities.containsKey(barcodeValue)) {
        oldQuantities[barcodeValue] =
            RxInt(existingProduct.quantity.value - quantity);
      } else {
        oldQuantities[barcodeValue]!.value =
            existingProduct.quantity.value - quantity;
      }
    } else {
      // If the product does not exist in scannedProducts, check in allProducts
      Product? productInAllProducts =
          findProductByBarcode(allProducts, barcodeValue);
      if (productInAllProducts != null) {
        // Remove from allProducts
        allProducts.remove(productInAllProducts);
      }

      // Add new product to scannedProducts
      Product newProduct = Product(
        id: productInAllProducts?.id ?? "0",
        itemLookupCode: barcodeValue,
        description: productInAllProducts?.description ??
            getProductNameScanned(barcodeValue),
        categoryCode: productInAllProducts?.categoryCode ?? "No Category",
        categoryName: productInAllProducts?.categoryName ?? "No Category",
        quantity: quantity,
      );
      scannedProducts.add(newProduct);
      _initializeTextController(barcodeValue, newProduct.quantity.toString());
      sendStockUpdateToApi(barcodeValue, quantity);
    }

    update(); // Ensure UI updates
    await saveProductsData(); // Optionally save the product data
  }

  Future<void> handleCameraInput() async {
    Get.dialog(CameraScanPage(
      onScanned: (barcodeValue) async {
        // This is a callback from the camera scan page
        Get.back(); // Close the camera page

        await Future.delayed(Duration(seconds: 1));

        _showQuantityDialog(barcodeValue);
      },
      allProducts: allProducts,
    ));
  }

  Product? findProductByBarcode(List<Product> productList, String barcode) {
    return productList
        .firstWhereOrNull((product) => product.itemLookupCode == barcode);
  }

  TextEditingController barcodeController = TextEditingController();
  TextEditingController quantityController = TextEditingController();

  // Handle manual input
  void handleManuallyInput() async {
    try {
      TextEditingController barcodeController = TextEditingController();
      TextEditingController quantityController = TextEditingController();

      Get.bottomSheet(
        Material(
          type: MaterialType.transparency,
          child: Container(
            height: 400.0,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Enter Barcode",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12.0),
                MyTextField(
                  controller: barcodeController,
                  hintText: "Enter barcode...",
                  borderColor: Colors.red,
                ),
                const SizedBox(height: 10.0),
                MyTextField(
                  controller: quantityController,
                  hintText: "Enter quantity...",
                  keyboardType: TextInputType.number,
                  borderColor: Colors.red,
                ),
                const SizedBox(height: 20.0),
                MyButton(
                  onTap: () {
                    final String barcodeValue = barcodeController.text.trim();
                    final String quantity = quantityController.text.trim();
                    if (barcodeValue.isNotEmpty && quantity.isNotEmpty) {
                      int qty = int.tryParse(quantity) ?? 0;
                      addOrUpdateProduct(barcodeValue,
                          qty); // Add or update the product quantity based on user input
                      Get.back(); // Dismiss the bottom sheet
                    }
                  },
                  label: "Enter Barcode",
                  height: 50.0,
                  borderRadius: 12.0,
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      throw Exception("Error handling manual input: $e");
    }
  }

  void cachingStockingDate() {
    prefs.setString("stocking_date", formatDate(DateTime.now()));
  }

  Future<void> startStocking() async {
    showStartButton = false;
    update();
    cachingStockingDate();
    await sendDataToApi(
      WarehouseStockProduct(
        barcode: "START_STOCKING",
        quantity: 0,
        stockingId: "",
        stockDate: retrieveStockingDate(),
        status: 1,
        storeId: storeData!.id,
      ),
    );
  }

  Future<void> endStocking() async {
    if (scannedProducts.isEmpty) return;
    Get.defaultDialog(
      title: "Confirm End Stocking",
      middleText: "Are you sure you want to complete the stocking process?",
      textCancel: "Cancel",
      textConfirm: "Confirm",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back(); // Close the dialog before proceeding
        await _processEndStocking();
      },
    );
  }

// Separate function for the actual stocking process
  Future<void> _processEndStocking() async {
    try {
      loading.value = true; // Show loading spinner

      if (!isConnected.value) {
        Get.snackbar("Error", "No internet connection.");
        loading.value = false;
        return;
      }

      // Send START_STOCKING request
      await sendDataToApi(
        WarehouseStockProduct(
          barcode: "START_STOCKING",
          quantity: 0,
          stockingId: "",
          stockDate: retrieveStockingDate(),
          status: 1,
          storeId: storeData?.id ?? "",
        ),
      );

      // Send scanned products
      for (var product in scannedProducts) {
        await sendDataToApi(WarehouseStockProduct(
          barcode: product.itemLookupCode,
          stockDate: retrieveStockingDate(),
          stockingId: "",
          status: 0,
          storeId: storeData?.id ?? "",
        ));
      }

      // Send END_STOCKING request
      await sendDataToApi(
        WarehouseStockProduct(
          stockingId: "",
          barcode: "END_STOCKING",
          stockDate: retrieveStockingDate(),
          status: 1,
          quantity: 0,
          storeId: storeData?.id ?? "",
        ),
      );

      // Clear stored data
      scannedProducts.clear();
      allProducts.clear();
      quantityControllers.clear();
      showStartButton = true;

      await prefs.remove("allProducts");
      await prefs.remove("scannedProducts");
      await prefs.remove("showStartButton");
      await prefs.remove("cached_barcodes");

      await Get.find<CategoryController>().clearStockingId();

      loading.value = false;
      update();

      // Show success message
      Get.snackbar("Success", "Stocking process completed successfully!",
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to complete stocking: ${e.toString()}");
      loading.value = false;
    }
  }

  Future<void> sendDataToApi(WarehouseStockProduct stockProduct) async {
    final Uri url =
        Uri.parse('https://visa-api.ck-report.online/api/Store/warehouseCheck');
    try {
      String deviceId = await getUniqueDeviceId();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'posserial': deviceId,
        },
        body: jsonEncode([stockProduct.toJson()]),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to send data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error occurred while sending data to API: $e");
    }
  }

  ProductStatus getProductStatus(String barcode) {
    // Check if the product is in scannedProducts
    Product? productInScanned =
        scannedProducts.firstWhereOrNull((p) => p.itemLookupCode == barcode);

    // Check if the product is in allProducts

    if (productInScanned != null) {
      if (productInScanned.categoryCode == catCode) {
        return ProductStatus.scannedCorrectCategory;
      }
    }
    return ProductStatus.scannedWrongCategory;
  }
}

enum ProductStatus {
  scannedCorrectCategory, // Scanned and in the correct category
  scannedWrongCategory, // Scanned but in the wrong category
}
