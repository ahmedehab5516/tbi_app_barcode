import 'dart:convert';
import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../common_files/snack_bar.dart';
import 'category_conroller.dart';
import '../models/product_data.dart';
import '../models/warehouse.dart';
import '../other_files/camera_scanner.dart';
import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import 'base_controller.dart'; // Import GetX for reactive programming

class WarehouseController extends BaseController {
  // ---------------------------
  // STATE & OBSERVABLES
  // ---------------------------
  final RxString barcode = "".obs;
  final RxMap<String, int> products = <String, int>{}.obs;
  final Map<String, TextEditingController> quantityControllers = {};
  final RxList<Product> allProducts = <Product>[].obs; // Store all products
  final RxList<Product> scannedProducts = <Product>[].obs;
  bool showStartButton = true;
  late String categoryCode; // The current category code

  final routeArgs = Get.arguments; // Get arguments passed to the screen


  // ---------------------------
  // LIFECYCLE METHODS
  // ---------------------------
  @override
  void onInit() {
    super.onInit();

    loadProductsInfo();
    loadCachedBarcodeData(); // Load cached barcode data if available.
  }

  @override
  void onClose() {
    for (final controller in quantityControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

// Retrieve the stocking date from SharedPreferences
  String retrieveStockingDate() {
    return prefs.getString("stocking_date") ?? formatDate(DateTime.now());
  }

// Cache the stocking date in SharedPreferences
  void cachingStockingDate() {
    prefs.setString("stocking_date", formatDate(DateTime.now()));
  }

// Cache the barcode data (the underlying products map) in SharedPreferences
  Future<void> cacheBarcodeData() async {
    String jsonData = jsonEncode(products);
    await prefs.setString("cached_barcodes", jsonData);
  }
// Define this method in WarehouseController

  String getProductName(String barcodeValue) {
    // Find the product based on the barcode
    final product =
        allProducts.firstWhereOrNull((p) => p.itemLookupCode == barcodeValue);

    // If the product is found, return its description, otherwise return a default message
    return product?.description ?? "Unregistered Product";
  }

  // ---------------------------
  // PRODUCT DATA HANDLING
  // ---------------------------
  Future<void> loadProductsInfo() async {
    final Uri url =
        Uri.parse("https://visa-api.ck-report.online/api/Store/loadItems");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        allProducts.clear();
        final ProductResponse productsData =
            ProductResponse.fromJson(jsonDecode(response.body));
        allProducts.addAll(productsData.data);
      } else {
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load products: ${e.toString()}");
      rethrow;
    }
  }

  // ---------------------------
  // CACHING BARCODE DATA
  // ---------------------------
  Future<void> loadCachedBarcodeData() async {
    startStocking();
    try {
      String? jsonData = prefs.getString("cached_barcodes");
      if (jsonData == null) {
        showStartButton = true;
      } else {
        Map<String, dynamic> decoded = jsonDecode(jsonData);
        products.clear();
        decoded.forEach((key, value) {
          getProductName(key);
          update();
          final int quantity =
              value is int ? value : int.tryParse(value.toString()) ?? 0;
          products[key] = quantity;
          initializeTextController(key);
          quantityControllers[key]?.text = quantity.toString();

          final WarehouseStockProduct stockUpdate = WarehouseStockProduct(
            barcode: key,
            stockDate: retrieveStockingDate(),
            stockingId: routeArgs['sid'],
            quantity: quantity,
            status: 0,
          );
          sendDataToApi(stockUpdate);
        });
        showStartButton = false;
      }
    } catch (e) {
      showStartButton = true;
      print("Error loading cached barcode data: $e");
    }
    update();
  }

  // ---------------------------
  // QUANTITY & CONTROLLER UPDATES
  // ---------------------------
  void incrementBarcodeCount(String barcodeValue,
      {bool isIncrement = true, String? newValue}) {
    final int oldQuantity = products[barcodeValue] ?? 0;

    // Convert newValue to int if provided; otherwise, calculate normally
    int newQuantity;
    if (newValue != null) {
      newQuantity = int.tryParse(newValue) ?? oldQuantity;
    } else {
      newQuantity = isIncrement
          ? oldQuantity + 1
          : (oldQuantity > 0 ? oldQuantity - 1 : 0);
    }

    // Update the product quantity map
    products[barcodeValue] = newQuantity;

    // Ensure a TextEditingController exists and update its text
    initializeTextController(barcodeValue);
    quantityControllers[barcodeValue]?.text = newQuantity.toString();

    // Calculate the difference in quantity
    final int quantityDelta = newQuantity - oldQuantity;
    if (quantityDelta != 0) {
      final WarehouseStockProduct stockUpdate = WarehouseStockProduct(
        barcode: barcodeValue,
        stockDate: retrieveStockingDate(),
        stockingId: routeArgs['sid'],
        quantity: quantityDelta,
        status: 0,
      );
      sendDataToApi(stockUpdate);
    }

    update();
    cacheBarcodeData();
  }

  void initializeTextController(String barcodeValue) {
    if (!quantityControllers.containsKey(barcodeValue)) {
      quantityControllers[barcodeValue] = TextEditingController(
        text: products[barcodeValue]?.toString() ?? '0',
      );
    }
  }

  // ---------------------------
  // BARCODE SCAN HANDLERS
  // ---------------------------
  void handleScannerInput(String barcodeValue, BuildContext context) async {
    incrementBarcodeCount(barcodeValue);
  }

  Future<void> handleCameraInput() async {
    Get.dialog(
      CameraScanPage(
        onScanned: (barcodeValue) async {
          Get.back(); // Close the camera scanner

          // Delay showing the quantity dialog for 1 second

          _showQuantityDialog(barcodeValue); // Show quantity input popup
        },
      ),
    );
  }

// Function to show a popup dialog for entering quantity
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
          incrementBarcodeCount(barcodeValue, newValue: enteredQuantity);
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

  // ---------------------------
  // MANUAL INPUT HANDLER
  // ---------------------------
  void handleManuallyInput() async {
    try {
      TextEditingController barcodeController = TextEditingController();
      TextEditingController quantityController = TextEditingController();
      showStartButton = false;

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
                      incrementBarcodeCount(barcodeValue, newValue: quantity);
                      Get.back();
                    } else {
                      SnackbarHelper.showFailure(
                          "Error", "Please enter a valid barcode.");
                    }
                  },
                  label: "Done",
                  height: 50.0,
                  borderRadius: 12.0,
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print("Error handling manual input: $e");
    }
  }

  // ---------------------------
  // STOCKING PROCESS
  // ---------------------------
  Future<void> startStocking() async {
    showStartButton = false;
    update();
    cachingStockingDate();
    await sendDataToApi(
      WarehouseStockProduct(
        barcode: "START_STOCKING",
        quantity: 0,
        stockingId: routeArgs['sid'],
        stockDate: retrieveStockingDate(),
        status: 1,
      ),
    );
  }

  Future<void> endStocking() async {
    try {
      // products.entries.map((entry) {
      //   return WarehouseStockProduct(
      //     barcode: entry.key,
      //     stockingId: routeArgs['sid'],
      //     quantity: entry.value,
      //     stockDate: retrieveStockingDate(),
      //     status: 0,
      //   );
      // }).toList();

      await sendDataToApi(
        WarehouseStockProduct(
          stockingId: routeArgs['sid'],
          barcode: "END_STOCKING",
          stockDate: retrieveStockingDate(),
          status: 1,
          quantity: 0,
        ),
      );

      scannedProducts.clear();
      products.clear();
      quantityControllers.clear();
      prefs.remove("cached_barcodes");
      await Get.find<CategoryController>().clearStockingId();
    
    } catch (e) {
      Get.snackbar("Error", "Failed to complete stocking: ${e.toString()}");
      rethrow;
    }
    showStartButton = true;
    update();
  }

  // ---------------------------
  // FILTER SCANNED PRODUCTS BY CATEGORY
  // ---------------------------
  List<Product> getFilteredScannedProducts() {
    return scannedProducts.where((product) {
      return product.categoryCode == categoryCode;
    }).toList();
  }

  // ---------------------------
  // API COMMUNICATION
  // ---------------------------
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
}
