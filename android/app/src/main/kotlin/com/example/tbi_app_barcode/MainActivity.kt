package com.example.tbi_app_barcode

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()

package com.example.tbi_app_barcode

import io.flutter.embedding.android.FlutterActivity // <-- Add this import
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() { // <-- Extend FlutterActivity
    // Optional: Configure plugins if needed
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        super.configureFlutterEngine(flutterEngine)
    }
}