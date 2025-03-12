import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../widgets/loading_indecator.dart';

import '../common_files/custom_button.dart';
import '../controllers/warehouse_controller.dart';
import '../models/product_data.dart';
import '../other_files/scanner.dart';
import '../widgets/native_side_field.dart';
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
          appBar: _buildWarehouseAppBar(controller),
          body: _buildBody(controller),
        );
      },
    );
  }

  /// Builds the custom AppBar.
  AppBar _buildWarehouseAppBar(WarehouseController controller) {
    return AppBar(
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
              constraints: const BoxConstraints(
                maxWidth: 250.0,
                minHeight: 16.0,
              ),
              child: Text(
                _warehouseController.storeData?.name ?? "",
                style: const TextStyle(fontSize: 10.0, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
    );
  }

  /// Builds the main body of the screen.
  Widget _buildBody(WarehouseController controller) {
    // Show a loading indicator if critical data is missing.
    if (controller.childCatCode!.isEmpty && controller.storeData!.id.isEmpty) {
      return const Center(child: BuildLoadingIndecator());
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
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
                      // Native Android view widget.
                      GetBuilder<WarehouseController>(
                        builder: (controller) {
                          return SizedBox(
                            width: double.infinity,
                            child: BuildAndroidView(
                                warecontroller: _warehouseController),
                          );
                        },
                      ),

                      // TabBarView for Scanned and Not Scanned Barcodes.
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Scanned Barcodes Tab.
                            buildSannedBarcodesTab(controller),
                            // Not Scanned Barcodes Tab.
                            buildNotScannedBarcodesYetTab(controller),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        // Global loading indicator overlay.
        Obx(() {
          return controller.loading.value
              ? const BuildLoadingIndecator()
              : const SizedBox.shrink();
        })
      ],
    );
  }

  Obx buildNotScannedBarcodesYetTab(WarehouseController controller) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: BuildLoadingIndecator());
      }
      List<Product> filteredProducts = [];
      if (controller.allProducts.isNotEmpty) {
        filteredProducts = controller.allProducts
            .where((p) => p.categoryCode == controller.childCatCode)
            .toList();
      } else {
        String? cachedProductsJson = controller.prefs.getString("allProducts");
        if (cachedProductsJson?.isNotEmpty ?? false) {
          List<dynamic> cachedProductsList = jsonDecode(cachedProductsJson!);
          filteredProducts = cachedProductsList
              .map((item) => Product.fromJson(item))
              .where((p) => p.categoryCode == controller.childCatCode)
              .toList();
        }
      }

      if (filteredProducts.isEmpty) {
        return const Center(child: Text("No Products in the Category"));
      }

      if (!controller.isConnected.value && controller.allProducts.isEmpty) {
        return Container(
          height: 100.0,
          width: 200.0,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              "You are offline. Some features may be limited.",
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
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
    });
  }

  Obx buildSannedBarcodesTab(WarehouseController controller) {
    return Obx(() {
      final filteredList = controller.scannedProducts
          .where((p) => p.itemLookupCode.isNotEmpty)
          .toList();
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                var product = filteredList[index];
                return GestureDetector(
                  onTap: () =>
                      controller.showAddQuantityDialog(product.itemLookupCode),
                  child: BuildScannedBarcodeCard(
                    warehouseController: controller,
                    barcode: product.itemLookupCode,
                    quantity: product.quantity.value,
                    stutas: controller.getProductStatus(product.itemLookupCode),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          BarcodeScannerWidget(
              onScanned: (value) =>
                  controller.handleScannerInput(value, context)),
          const SizedBox(height: 10),
          Obx(
            () => MyButton(
              key: const ValueKey("endButton"),
              onTap: () async {
                FocusScope.of(context).unfocus();
                if (!controller.loading.value) {
                  await controller.endStocking();
                }
              },
              backgroundColor:
                  controller.loading.value || controller.scannedProducts.isEmpty
                      ? Colors.grey.shade600
                      : Colors.red,
              label: "End Stocking",
            ),
          ),
        ],
      );
    });
  }
}
