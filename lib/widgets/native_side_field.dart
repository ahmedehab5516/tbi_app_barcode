import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common_files/custom_button.dart';
import '../common_files/text_field.dart';
import '../controllers/warehouse_controller.dart';

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
  // Use the shared channel since there's only one view.
  final MethodChannel _textChannel =
      MethodChannel("com.example.tbi_app_barcode/getBarcode");
  Timer? _barcodeProcessingTimer;
  final FocusNode _countNode = FocusNode();

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
                  child: AndroidView(
                    viewType: 'android_edit_text',
                    layoutDirection: TextDirection.ltr,
                    onPlatformViewCreated: (int id) {
                      // Start processing barcode input.
                      _processScannedBarcode();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                flex: 2,
                child: MyTextField(
                  controller: widget.warecontroller.quantityController,
                  hintText: "Count",
                  keyboardType: TextInputType.numberWithOptions(
                      signed: true, decimal: false),
                  borderColor: Colors.red,
                  node: _countNode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Align(
            alignment: Alignment.centerRight,
            child: MyButton(
              onTap: () async {
                // Process manual barcode input from the native EditText.
                await _processManualBarcodeInput();
                // Clear and focus the native EditText.
                await _textChannel.invokeMethod("clearAndFocus");
                // Clear the Count text field.
                widget.warecontroller.quantityController.clear();
              },
              label: "Enter Barcode",
              height: 50.0,
              borderRadius: 12.0,
              backgroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processScannedBarcode() async {
    try {
      final String text = await _textChannel.invokeMethod("getBarcode");
      if (text.isNotEmpty) {
        _barcodeProcessingTimer?.cancel();
        _barcodeProcessingTimer = Timer(const Duration(milliseconds: 300), () {
          widget.warecontroller.addOrUpdateProduct(text, 1);
        });
      }
    } catch (e) {
      throw ("Error getting scanned text: $e");
    }
  }

  Future<void> _processManualBarcodeInput() async {
    try {
      final String text = await _textChannel.invokeMethod("getBarcode");
      widget.warecontroller.barcodeController.text = text;
      final String quantity =
          widget.warecontroller.quantityController.text.trim();
      int qty = int.tryParse(quantity) ?? 0;

      // Allow processing even when qty is negative or zero.
      if (text.isNotEmpty) {
        // widget.warecontroller.addOrUpdateProduct(text, qty);
        // widget.warecontroller.updateProductQuantity(text, qty);
        widget.warecontroller.updateOrAddProduct(text, qty);
      }
    } catch (e) {
      throw ("Error getting text from NativeView: $e");
    }
  }
}
