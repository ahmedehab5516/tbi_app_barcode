import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product_data.dart';

import '../common_files/snack_bar.dart';

class CameraScanPage extends StatefulWidget {
  const CameraScanPage(
      {super.key, required this.onScanned, required this.allProducts});
  final Function(String) onScanned;
  final List<Product> allProducts;

  @override
  _CameraScanPageState createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  late MobileScannerController _controller;
  Set<String> scannedBarcodes = {};
  bool isScanningPaused = false;
  bool isFlashOn = false;
  bool isDividerMoving = false;
  Timer? _dividerTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
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
    _dividerTimer?.cancel();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startDividerMovement() {
    _dividerTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        isDividerMoving = !isDividerMoving;
      });
    });
  }

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    _controller.toggleTorch();
  }

  Future<void> _playBeep() async {
    await _audioPlayer.play(AssetSource('audios/beep.mp3'));
    await Future.delayed(Duration(seconds: 1));
  }

  void _handleBarcodeDetected(String barcodeValue) async {
    barcodeValue = barcodeValue.trim();

    if (scannedBarcodes.contains(barcodeValue)) {
      SnackbarHelper.showFailure(
          "Duplicate Scan", "This barcode has already been scanned.");
      return;
    }

    scannedBarcodes.add(barcodeValue);
    setState(() {
      isScanningPaused = true;
    });

    await _playBeep(); // Play beep sound
    if (widget.allProducts.any((p) => p.itemLookupCode == barcodeValue)) {
      widget.onScanned(barcodeValue);
    } else {
      // If the product does not exist in allProducts, consider it unregistered
      widget.onScanned(barcodeValue);
    }

    SnackbarHelper.showSuccess(
        "Scan Complete", "Barcode $barcodeValue successfully scanned!");

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
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture barcodeCapture) async {
              final String? barcodeValue =
                  barcodeCapture.barcodes.first.rawValue;
              if (barcodeValue == null || isScanningPaused) return;
              _handleBarcodeDetected(barcodeValue);
            },
          ),
          Center(
            child: Container(
              width: 300.0,
              height: 150.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withOpacity(0.4),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    top: isDividerMoving ? 140.0 : 0.0,
                    left: 0.0,
                    right: 0.0,
                    duration: Duration(milliseconds: 1000),
                    child: Divider(
                      color: Colors.red,
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
