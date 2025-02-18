import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import '../other_files/scanner.dart';

import '../common_files/custom_button.dart';
import '../controllers/warehouse_controller.dart';
import '../widgets/barcode_card.dart';

class WarehouseScreen extends StatelessWidget {
  final WarehouseController _warehouseController =
      Get.find<WarehouseController>();

      

  WarehouseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WarehouseController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            leadingWidth: 150.0,
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Image.asset(
                "assets/images/idpgH2alr7_1738673273412.png",
                width: double.infinity,
                height: 40.0,
                color: Colors.white,
              ),
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
          ),
          body: Padding(
            padding: const EdgeInsets.all(12.0),
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
                        controller.products.isEmpty
                            ? const Center(child: Text("Start scanning"))
                            : Container(),
                        Expanded(
                          child: ListView(
                            children: controller.products.entries.map((entry) {
                              return BuildBarcodeCard(
                                warehouseController: controller,
                                barcode: entry.key,
                                quantity: entry.value,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        BarcodeScannerWidget(
                          onScanned: (value) =>
                              controller.handleScannerInput(value, context),
                        ),
                        const SizedBox(height: 10),
                        MyButton(
                          key: const ValueKey("endButton"),
                          onTap: () async => await controller.endStocking(),
                          label: "End Stocking",
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
