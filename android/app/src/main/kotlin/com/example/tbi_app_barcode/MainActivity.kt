package com.example.tbi_app_barcode

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BARCODE_CHANNEL = "com.example.tbi_app_barcode/getBarcode"
    private val FLAG_CHANNEL = "com.example.tbi_app_barcode/textFieldFlag"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val barcodeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BARCODE_CHANNEL)
        val flagChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLAG_CHANNEL)

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("android_edit_text", NativeEditTextFactory(barcodeChannel, flagChannel))
    }
}
