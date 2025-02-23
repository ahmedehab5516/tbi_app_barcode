import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../controllers/warehouse_controller.dart';

class BuildScannedBarcodeCard extends StatelessWidget {
  const BuildScannedBarcodeCard({
    super.key,
    required WarehouseController warehouseController,
    required this.barcode,
    required this.quantity,
  }) : _warehouseController = warehouseController;

  final WarehouseController _warehouseController;
  final String barcode;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 0),
      decoration: BoxDecoration(
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
                      color: Colors.grey,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Counter section with icons

            Expanded(
              child: Row(
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
                    width: 74.0,
                    child: TextFormField(
                      controller:
                          _warehouseController.quantityControllers[barcode],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16.0),
                      onChanged: (value) {
                        String newQuantity = value;

                        print("rrrrrrrrrrrrr$newQuantity");

                        _warehouseController.incrementBarcodeCount(
                          barcode,
                          newValue: newQuantity,
                        );
                      },
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
            ),
          ],
        ),
      ),
    );
  }
}
