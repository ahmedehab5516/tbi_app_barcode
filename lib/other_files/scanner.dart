import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onScanned; // Callback function for barcode scan

  const BarcodeScannerWidget({super.key, required this.onScanned});

  @override
  _BarcodeScannerWidgetState createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  @override
  Widget build(BuildContext context) {
    return BarcodeKeyboardListener(
      onBarcodeScanned: widget.onScanned,
      child:
          Container(), // This widget listens for barcode input in the background
    );
  }
}
