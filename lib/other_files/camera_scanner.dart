import 'dart:async'; // Import for Timer functionality
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:tbi_app_barcode/common_files/snack_bar.dart';

class CameraScanPage extends StatefulWidget {
  const CameraScanPage({super.key, required this.onScanned});
  final Function(String) onScanned; // Callback for the scanned barcode

  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  late MobileScannerController _controller; // Controller to handle scanner
  Set<String> scannedBarcodes = {}; // Set to track scanned barcodes
  bool isScanningPaused = false;
  bool isFlashOn = false; // Flash toggle state
  bool isDividerMoving = false; // Flag for moving divider
  Timer? _dividerTimer; // Timer to control the movement of the divider

  @override
  void initState() {
    super.initState();

    // Change the status bar color to black or transparent to avoid the red color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor:
            Colors.transparent, // Set the status bar color to transparent
        statusBarIconBrightness:
            Brightness.light, // Optionally set the icons to light
      ),
    );

    _controller = MobileScannerController(
      detectionTimeoutMs: 100,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _startDividerMovement();
    _controller.start();
  }

  @override
  void dispose() {
    _dividerTimer?.cancel(); // Cancel the divider timer
    _controller.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  // Function to toggle divider movement
  void _startDividerMovement() {
    _dividerTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        isDividerMoving = !isDividerMoving;
      });
    });
  }

  // Function to toggle flashlight
  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    _controller.toggleTorch(); // Toggle torch using MobileScannerController
  }

  // Function to handle barcode detection and show Snackbar
  void _handleBarcodeDetected(String barcodeValue) {
    barcodeValue = barcodeValue.trim(); // Trim any unnecessary whitespace

    // Check if the barcode is a duplicate
    if (scannedBarcodes.contains(barcodeValue)) {
      SnackbarHelper.showFailure(
        "Duplicate Scan",
        "This barcode has already been scanned.",
      );
      return;
    }

    // Add barcode to the set and show success
    scannedBarcodes.add(barcodeValue);

    setState(() {
      isScanningPaused = true;
    });

    // Call the onScanned callback to trigger the barcode handling in the parent widget
    widget.onScanned(barcodeValue);

    SnackbarHelper.showSuccess(
      "Scan Complete",
      "Barcode $barcodeValue successfully scanned!",
    );

    // Simulate a 2-second delay to stop scanning and reset the state
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        isScanningPaused = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Barcode Scanner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // Show the list of scanned barcodes
              Get.defaultDialog(
                title: 'Scanned Barcodes',
                content: SingleChildScrollView(
                  child: Column(
                    children: scannedBarcodes
                        .map((barcode) => ListTile(title: Text(barcode)))
                        .toList(),
                  ),
                ),
                barrierDismissible: true,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // MobileScanner widget to capture barcodes
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture barcodeCapture) async {
              final String? barcodeValue =
                  barcodeCapture.barcodes.first.rawValue;

              if (barcodeValue == null || isScanningPaused) return;

              // Handle barcode detection and pass it to the parent callback
              _handleBarcodeDetected(barcodeValue);
            },
          ),

          // Center rectangle container to guide the user where to scan
          Center(
            child: Container(
              width: 300.0,
              height: 150.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
                color: Colors.black
                    .withOpacity(0.4), // Semi-transparent background
              ),
              child: Stack(
                children: [
                  // Moving divider inside the container
                  AnimatedPositioned(
                    top: isDividerMoving ? 140.0 : 0.0, // Move the divider
                    left: 0.0,
                    right: 0.0,
                    duration: Duration(milliseconds: 1000),
                    child: Divider(
                      color: Colors.red, // Red color for the divider
                      thickness: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFlash,
        backgroundColor: Colors.red,
        child: Icon(
          isFlashOn ? Icons.flash_on : Icons.flash_off,
          color: Colors.white,
        ),
      ),
    );
  }
}
