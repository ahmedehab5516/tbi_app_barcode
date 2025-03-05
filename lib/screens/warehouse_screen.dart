import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import '../controllers/warehouse_controller.dart';
import '../models/product_data.dart';
import '../other_files/scanner.dart';
import '../widgets/not_scanned_barcode_card.dart';
import '../widgets/scanned_barcode_card.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({super.key});

  @override
  _WarehouseScreenState createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WarehouseController _warehouseController =
      Get.find<WarehouseController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WarehouseController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            leadingWidth: 150.0,
            leading: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.asset(
                    "assets/images/idpgH2alr7_1738673273412.png",
                    width: double.infinity,
                    height: 40.0,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 250.0, // Set a maximum width
                      minHeight: 16.0, // Set a minimum height
                    ),
                    child: Text(
                      _warehouseController.storeData.name,
                      style: TextStyle(fontSize: 10.0, color: Colors.white),
                      overflow: TextOverflow
                          .ellipsis, // To handle overflow if the text is too long
                      maxLines: 1, // Ensures the text doesn't wrap
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Visibility(
                visible: !controller.showStartButton,
                child: IconButton(
                  tooltip: "Scan Barcode",
                  icon: const Icon(
                    FontAwesomeIcons.camera,
                    size: 20.0,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    controller.handleCameraInput();
                  },
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Scanned Barcodes"),
                Tab(text: "Not Scanned Barcodes"),
              ],
            ),
          ),
          body: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: controller.showStartButton
                  ? Center(
                      key: const ValueKey("startButton"),
                      child: SizedBox(
                        height: 70.0,
                        child: MyButton(
                          onTap: () async => await controller.startStocking(),
                          label: "Start Stocking",
                        ),
                      ),
                    )
                  : Column(
                      key: const ValueKey("stockingView"),
                      children: [
                        GetBuilder<WarehouseController>(
                          builder: (controller) => SizedBox(
                              width: double.infinity,
                              child: BuildAndroidView(
                                warecontroller: _warehouseController,
                              )),
                        ),
                        // TabView
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Scanned Barcodes View
                              Obx(() {
                                final filteredList = controller.scannedProducts
                                    .where((p) =>
                                        p.itemLookupCode.isNotEmpty &&
                                        p.quantity > 0)
                                    .toList();
                                return Column(
                                  children: [
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: filteredList.length,
                                        itemBuilder: (context, index) {
                                          var product = filteredList[index];
                                          return GestureDetector(
                                            onTap: () => controller
                                                .showAddQuantityDialog(
                                                    product.itemLookupCode),
                                            child: BuildScannedBarcodeCard(
                                                warehouseController: controller,
                                                barcode: product.itemLookupCode,
                                                quantity:
                                                    product.quantity.value,
                                                stutas: controller
                                                    .getProductStatus(product
                                                        .itemLookupCode)),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    BarcodeScannerWidget(
                                        onScanned: (value) =>
                                            controller.handleScannerInput(
                                                value, context)),
                                    const SizedBox(height: 10),
                                    MyButton(
                                      key: const ValueKey("endButton"),
                                      onTap: () async =>
                                          await controller.endStocking(),
                                      label: "End Stocking",
                                    ),
                                  ],
                                );
                              }),
                              Obx(() {
                                // Show loading spinner while data is being fetched
                                if (controller.loading.value) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                // Fallback to cached products if allProducts is empty
                                List<Product> filteredProducts;

                                if (controller.allProducts.isNotEmpty) {
                                  // Filter allProducts if it's not empty
                                  filteredProducts = controller.allProducts
                                      .where((p) =>
                                          p.categoryCode == controller.catCode)
                                      .toList();
                                } else {
                                  // Fallback to cached products
                                  String? cachedProductsJson =
                                      controller.prefs.getString("allProducts");
                                  if (cachedProductsJson != null && cachedProductsJson.isNotEmpty) {
                                    List<dynamic> cachedProductsList =
                                        jsonDecode(cachedProductsJson);
                                    filteredProducts = cachedProductsList
                                        .map((item) => Product.fromJson(item))
                                        .where((p) =>
                                            p.categoryCode ==
                                            controller.catCode)
                                        .toList();
                                  } else {
                                    filteredProducts = [];
                                  }
                                }

                                // Return a message if no products are found
                                if (filteredProducts.isEmpty) {
                                  return const Center(
                                      child:
                                          Text("No Products in the Category"));
                                }

                                return ListView.builder(
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    var product = filteredProducts[index];
                                    return BuildNotScannedBarcodeCard(
                                      warehouseController: controller,
                                      barcode: product.itemLookupCode,
                                      quantity: product.quantity.value,
                                    );
                                  },
                                );
                              })
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class BuildAndroidView extends StatefulWidget {
  final WarehouseController warecontroller;

  const BuildAndroidView({
    super.key,
    required this.warecontroller,
  });

  @override
  _BuildAndroidViewState createState() => _BuildAndroidViewState();
}

class _BuildAndroidViewState extends State<BuildAndroidView> {
  final MethodChannel _textChannel =
      MethodChannel("com.example.tbi_app_barcode/text");

  Timer? _barcodeProcessingTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _barcodeProcessingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 60,
                  child: FocusScope(
                    canRequestFocus: false,
                    child: AndroidView(
                      viewType: 'android_edit_text',
                      layoutDirection: TextDirection.ltr,
                      onPlatformViewCreated: (int id) {
                        _processScannedBarcode();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                flex: 2,
                child: MyTextField(
                  controller: widget.warecontroller.quantityController,
                  hintText: "Count",
                  keyboardType: TextInputType.number,
                  borderColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Align(
            alignment: Alignment.centerRight,
            child: MyButton(
              onTap: () async {
                await _processManualBarcodeInput();
              },
              label: "Enter Barcode",
              height: 50.0,
              borderRadius: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Automatically processes barcode input when `isOffStage = true` (Scanner Mode)
  Future<void> _processScannedBarcode() async {
    try {
      final String text = await _textChannel.invokeMethod("getText");
      if (text.isNotEmpty) {
        // Process barcode with a delay
        _barcodeProcessingTimer?.cancel();
        _barcodeProcessingTimer = Timer(const Duration(milliseconds: 300), () {
          widget.warecontroller
              .addOrUpdateProduct(text, 1); // Default quantity = 1 for scanning
        });
      }
    } catch (e) {
      throw ("Error getting scanned text: $e");
    }
  }

  /// Fetch barcode manually when `isOffStage = false` (Manual Mode)
  Future<void> _processManualBarcodeInput() async {
    try {
      final String text = await _textChannel.invokeMethod("getText");
      widget.warecontroller.barcodeController.text =
          text; // Autofill barcode field

      final String quantity =
          widget.warecontroller.quantityController.text.trim();
      int qty = int.tryParse(quantity) ?? 0;

      if (text.isNotEmpty && qty > 0) {
        widget.warecontroller.addOrUpdateProduct(text, qty);
      }
    } catch (e) {
      throw ("Error getting text from NativeView: $e");
    }
  }
}
