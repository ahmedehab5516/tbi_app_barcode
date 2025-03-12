import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../controllers/warehouse_controller.dart';

class BuildScannedBarcodeCard extends StatelessWidget {
  const BuildScannedBarcodeCard({
    super.key,
    required WarehouseController warehouseController,
    required this.barcode,
    required this.quantity,
    required this.stutas,
  }) : _warehouseController = warehouseController;

  final WarehouseController _warehouseController;
  final String barcode;
  final int quantity;
  final ProductStatus stutas;

  Color getProductColor() {
    // Check if the product is not in allProducts.
    if (_warehouseController.getProductNameScanned(barcode) ==
        "Unregistered Product") {
      return Colors.red;
    }

    // Otherwise, determine color based on its status.
    switch (stutas) {
      case ProductStatus.scannedCorrectCategory:
        return Colors.white;
      case ProductStatus.scannedWrongCategory:
        return Colors.amber;
      default:
        return Colors.grey; // Fallback color if needed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
      decoration: BoxDecoration(
        color: getProductColor(),
        border: Border.all(
          color: Colors.red,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Product name
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 200.0,
                    ),
                    child: Text(
                      _warehouseController.getProductNameScanned(barcode),
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.start,
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  // Barcode in the center
                  Text(
                    barcode,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Counter section with icons

            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      // Minus icon
                      IconButton(
                        onPressed: () {
                          _warehouseController.incrementBarcodeCount(barcode,
                              delta: -1);
                        },
                        icon: const Icon(FontAwesomeIcons.minus),
                      ),
                      // Editable quantity counter
                      SizedBox(
                        width: screenWidth * 0.17,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Text(
                            _warehouseController
                                .quantityControllers[barcode]!.value.text,
                            style: const TextStyle(fontSize: 16.0),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Plus icon
                      IconButton(
                        onPressed: () {
                          _warehouseController.incrementBarcodeCount(barcode);
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  Obx(() {
                    // Get the previous quantity for the specific barcode
                    int previousQuantity =
                        _warehouseController.oldQuantities[barcode]?.value ?? 0;

                    // Only display the text if the previous quantity is greater than 0
                    if (previousQuantity > 0) {
                      return Text('Previous Quantity: $previousQuantity');
                    }

                    // If previous quantity is 0 or null, return an empty widget
                    return SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
