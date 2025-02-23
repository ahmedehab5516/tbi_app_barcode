import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../widgets/not_scanned_barcode_card.dart';
import '../widgets/scanned_barcode_card.dart';
import '../models/product_data.dart';
import '../other_files/scanner.dart';
import '../common_files/custom_button.dart';
import '../controllers/warehouse_controller.dart';

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
              Visibility(
                visible: !controller.showStartButton,
                child: IconButton(
                  tooltip: "Manual Entry",
                  icon: const Icon(
                    FontAwesomeIcons.pen,
                    size: 20.0,
                    color: Colors.white,
                  ),
                  onPressed: () => controller.handleManuallyInput(),
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
                                      onScanned: (value) => controller
                                          .handleScannerInput(value, context),
                                    ),
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

                              // Not Scanned Barcodes View
                              Obx(() {
                                var filteredProducts = controller.allProducts
                                    .where((p) =>
                                        p.categoryCode ==
                                        controller.routeArgs['catCode'])
                                    .toList();
                                var uniqueFilteredProducts = <Product>[];

                                for (var product in filteredProducts) {
                                  if (!uniqueFilteredProducts.any((p) =>
                                      p.itemLookupCode ==
                                      product.itemLookupCode)) {
                                    uniqueFilteredProducts.add(product);
                                  }
                                }

                                return controller.allProducts.isEmpty
                                    ? const Center(
                                        child: Text("Start scanning"))
                                    : ListView.builder(
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
                              }),
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
