package com.example.tbi_app_barcode

import android.content.Context
import android.view.View
import android.widget.EditText
import android.view.inputmethod.InputMethodManager
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.MethodChannel

class NativeEditText(context: Context, private val methodChannel: MethodChannel) : PlatformView {
    private val editText: EditText = EditText(context).apply {
        hint = "Enter barcode..."
        textSize = 18f
        isFocusableInTouchMode = true // Enable focus
        requestFocus() // Auto-focus when the view is created
    }

    init {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getText" -> result.success(editText.text.toString()) // Return input text
                "clearText" -> {
                    editText.text.clear()
                    result.success(null)
                }
                "disableKeyboard" -> disableKeyboard() // Hide keyboard when scanning
                else -> result.notImplemented()
            }
        }
    }

    private fun disableKeyboard() {
        val imm = editText.context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        imm.hideSoftInputFromWindow(editText.windowToken, 0)
    }

    override fun getView(): View {
        return editText
    }

    override fun dispose() {}
}
