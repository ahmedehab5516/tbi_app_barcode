import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner_plus/flutter_barcode_scanner_plus.dart';

import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'package:tbi_app_barcode/common_files/snack_bar.dart';
import 'package:tbi_app_barcode/other_files/camera_scanner.dart';

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
    _barcodeStreamController.close();
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
  final StreamController<String> _barcodeStreamController =
      StreamController<String>.broadcast();

  Stream<String> get barcodeStream => _barcodeStreamController.stream;
  bool _isScanningPaused = false; // Prevent multiple scans

  Future<void> handleCameraInrput() async {
    Set<String> scannedBarcodes =
        {}; // Set to keep track of already scanned barcodes

    try {
      Stream<String>? barcodeStream =
          FlutterBarcodeScanner.getBarcodeStreamReceiver(
        "#ff6666",
        "Cancel",
        true,
        ScanMode.BARCODE,
      )?.map((event) => event.toString());

      barcodeStream?.listen((barcodeValue) async {
        // If the barcode is valid and scanning is not paused
        if (barcodeValue != "-1" && !_isScanningPaused) {
          if (scannedBarcodes.contains(barcodeValue)) {
            // Show message for duplicate barcode
            Get.snackbar(
              "Duplicate Scan",
              "This barcode has already been scanned.",
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange.withOpacity(0.8),
              colorText: Colors.white,
            );
            return; // Skip the rest of the process if the barcode was scanned before
          }

          // Add barcode to the scanned set
          scannedBarcodes.add(barcodeValue);

          // Pause scanning for the feedback to be visible
          _isScanningPaused = true;

          // Show progress indicator while processing
          Get.dialog(
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              ),
            ),
            barrierDismissible: false,
          );

          // Simulate some processing time (e.g., saving data, etc.)
          await Future.delayed(Duration(seconds: 1));

          // Close progress indicator
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }

          // Show success snackbar once the scan is complete
          Get.snackbar(
            "Scan Complete",
            "Barcode $barcodeValue successfully scanned!",
            snackPosition:
                SnackPosition.TOP, // Show the snackbar on top of the camera
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
          );

          // Resume scanning after the snackbar
          await Future.delayed(
              Duration(seconds: 2)); // Allow snackbar to be visible
          _isScanningPaused = false; // Resume scanning for the next barcode
        } else {
          // Handle canceled or invalid scan
          if (barcodeValue == "-1") {
            Get.snackbar(
              "Scan Canceled",
              "The scanning process was canceled.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.withOpacity(0.8),
              colorText: Colors.white,
            );
          }
        }
      });
    } catch (e) {
      _barcodeStreamController
          .addError(Exception("Error scanning barcode: $e"));
      Get.snackbar(
        "Error",
        "An error occurred while scanning the barcode.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void handleCameraInput() {
    Get.dialog(CameraScanPage(
      onScanned: (barcodeValue) {
        incrementBarcodeCount(barcodeValue);
      },
    ));
  }

  // ---------------------------
  // MANUAL INPUT HANDLER
  // ---------------------------
  void handleManuallyInput() async {
    try {
      TextEditingController inputController = TextEditingController();
      showStartButton = false;

      // Use a bottom sheet with rounded corners and a clean layout
      Get.bottomSheet(
        Material(
          type: MaterialType.transparency,
          child: Container(
            height: 400.0, // Adjusted height for better fit
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8.0,
                  spreadRadius: 2.0,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add title or header
                Text(
                  "Enter Barcode",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12.0),
                MyTextField(
                  controller: inputController,
                  hintText: "Enter barcode...",
                  keyboardType: TextInputType.text,
                  borderColor: Colors.blueAccent,
                ),
                const SizedBox(height: 20.0),
                // Done button with modern style
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
                      SnackbarHelper.showFailure(
                          "Error", "Please enter a valid barcode.");
                    }
                  },
                  label: "Done",
                  height: 50.0, // Increased button height for better tap target

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
