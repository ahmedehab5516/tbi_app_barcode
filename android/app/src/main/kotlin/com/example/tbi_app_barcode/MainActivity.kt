package com.example.tbi_app_barcode

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TEXT_CHANNEL = "com.example.tbi_app_barcode/text"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TEXT_CHANNEL)

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("android_edit_text", NativeEditTextFactory(methodChannel))
    }
}
