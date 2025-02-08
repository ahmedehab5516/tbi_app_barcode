import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;

import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import '../models/product_data.dart';
import '../models/warehouse.dart';
import 'base_controller.dart';

class WarehouseController extends BaseController {
  // ---------------------------
  // STATE & OBSERVABLES
  // ---------------------------
  final RxString barcode = "".obs;
  final RxMap<String, int> products = <String, int>{}.obs;
  final Map<String, TextEditingController> quantityControllers = {};
  List<Product> allProducts = [];
  bool showStartButton = true;
  final List<WarehouseStockProduct> scannedProducts = [];

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
        final ProductData productsData =
            ProductData.fromJson(jsonDecode(response.body));
        allProducts.addAll(productsData.data);
      } else {
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load products: ${e.toString()}");
      rethrow;
    }
  }

  String getProductName(String barcodeValue) {
    final product =
        allProducts.firstWhereOrNull((p) => p.itemLookupCode == barcodeValue);
    return product?.description ?? "Unregistered Product";
  }

  // ---------------------------
  // STOCKING DATE MANAGEMENT
  // ---------------------------
  void cachingStockingDate() {
    prefs.setString("stocking_date", formatDate(DateTime.now()));
  }

  String retrieveStockingDate() {
    return prefs.getString("stocking_date") ?? formatDate(DateTime.now());
  }

  void removeStockingDate() {
    prefs.remove("stocking_date");
  }

  // ---------------------------
  // CACHING BARCODE DATA
  // ---------------------------
  /// Caches the current barcode data (the underlying products map) in SharedPreferences.
  Future<void> cacheBarcodeData() async {
    // Encode the underlying Map directly.
    String jsonData = jsonEncode(products);
    await prefs.setString("cached_barcodes", jsonData);
  }

  /// Loads cached barcode data from SharedPreferences, if available.
  Future<void> loadCachedBarcodeData() async {
    startStocking();
    try {
      String? jsonData = prefs.getString("cached_barcodes");
      if (jsonData == null) {
        showStartButton = true;
      } else {
        // Cached data is available.
        Map<String, dynamic> decoded = jsonDecode(jsonData);
        products.clear();
        decoded.forEach((key, value) {
          final int quantity =
              value is int ? value : int.tryParse(value.toString()) ?? 0;
          products[key] = quantity;
          initializeTextController(key);
          quantityControllers[key]?.text = quantity.toString();

          final WarehouseStockProduct stockUpdate = WarehouseStockProduct(
            barcode: key,
            stockDate: retrieveStockingDate(),
            quantity: quantity,
            status: 0,
          );
          sendDataToApi(stockUpdate);
        });
        // Hide the start button as stocking is already in progress.
        showStartButton = false;
      }
    } catch (e) {
      // In case of any error, fallback to showing the start button.
      showStartButton = true;
      print("Error loading cached barcode data: $e");
    }
    update();
  }

  // ---------------------------
  // QUANTITY & CONTROLLER UPDATES
  // ---------------------------
  /// Increments (or decrements) the quantity for a given barcode by one,
  /// updates local state and UI, sends an API update, and caches the data.
  void incrementBarcodeCount(String barcodeValue, {bool isIncrement = true}) {
    final int oldQuantity = products[barcodeValue] ?? 0;
    final int newQuantity =
        isIncrement ? oldQuantity + 1 : (oldQuantity > 0 ? oldQuantity - 1 : 0);
    products[barcodeValue] = newQuantity;

    // Ensure a TextEditingController exists and update its text.
    initializeTextController(barcodeValue);
    quantityControllers[barcodeValue]?.text = newQuantity.toString();

    final int quantityDelta = newQuantity - oldQuantity;
    if (quantityDelta != 0) {
      final WarehouseStockProduct stockUpdate = WarehouseStockProduct(
        barcode: barcodeValue,
        stockDate: retrieveStockingDate(),
        quantity: quantityDelta,
        status: 0,
      );
      sendDataToApi(stockUpdate);
    }
    update();
    cacheBarcodeData();
  }

  /// Ensures that a TextEditingController exists for the given barcode.
  void initializeTextController(String barcodeValue) {
    if (!quantityControllers.containsKey(barcodeValue)) {
      quantityControllers[barcodeValue] = TextEditingController(
        text: products[barcodeValue]?.toString() ?? '0',
      );
    }
  }

  // ---------------------------
  // BARCODE INPUT HANDLERS
  // ---------------------------
  /// Handles barcode input via a hardware scanner.
  void handleScannerInput(String barcodeValue, BuildContext context) async {
    incrementBarcodeCount(barcodeValue);
  }

  /// Handles barcode input via the device camera.
  Future<void> handleCameraInput() async {
    try {
      String barcodeValue = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", // Scan overlay color
        "Cancel", // Cancel button text
        true, // Show flash icon
        ScanMode.BARCODE, // Scan mode
      );
      if (barcodeValue != "-1") {
        showStartButton = false;
        update();
        incrementBarcodeCount(barcodeValue);
        print("Barcode scanned: $barcodeValue");
      } else {
        print("Scanning canceled");
      }
    } catch (e) {
      throw Exception("Error scanning barcode: $e");
    }
  }

  // ---------------------------
  // MANUAL INPUT HANDLER
  // ---------------------------
  void handleManuallyInput() async {
    try {
      TextEditingController inputController = TextEditingController();
      showStartButton = false;
      Get.bottomSheet(
        Material(
          type: MaterialType.transparency,
          child: Container(
            height: 500.0,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MyTextField(
                  controller: inputController,
                  hintText: "Enter barcode...",
                  
                ),
                const SizedBox(height: 20.0),
                MyButton(
                  onTap: () {
                    final String barcodeValue = inputController.text.trim();
                    if (barcodeValue.isNotEmpty) {
                      if (!quantityControllers.containsKey(barcodeValue)) {
                        initializeTextController(barcodeValue);
                      }
                      incrementBarcodeCount(barcodeValue);
                      Get.back(); // Close the bottom sheet.
                    } else {
                      Get.snackbar("Error", "Please enter a barcode.");
                    }
                  },
                  label: "Done",
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
        stockDate: retrieveStockingDate(),
        status: 1,
      ),
    );
  }

  Future<void> endStocking() async {
    try {
      final List<WarehouseStockProduct> stockUpdates =
          products.entries.map((entry) {
        return WarehouseStockProduct(
          barcode: entry.key,
          quantity: entry.value,
          stockDate: retrieveStockingDate(),
          status: 0,
        );
      }).toList();

      // Send end stocking marker.
      await sendDataToApi(
        WarehouseStockProduct(
          barcode: "END_STOCKING",
          stockDate: retrieveStockingDate(),
          status: 1,
          quantity: 0,
        ),
      );

      // Clear local data after successful submission.
      scannedProducts.clear();
      products.clear();
      quantityControllers.clear();
      prefs.remove("cached_barcodes");
    } catch (e) {
      Get.snackbar("Error", "Failed to complete stocking: ${e.toString()}");
      rethrow;
    }
    showStartButton = true;
    update();
  }

  // ---------------------------
  // API COMMUNICATION
  // ---------------------------
  /// Sends a [WarehouseStockProduct] update to the backend.
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
      if (response.statusCode == 200) {
        // Optionally handle a successful response.
      } else {
        throw Exception(
            "Failed to send data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error occurred while sending data to API: $e");
    }
  }
}
