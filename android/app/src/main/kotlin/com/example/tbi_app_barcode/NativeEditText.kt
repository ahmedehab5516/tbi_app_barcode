package com.example.tbi_app_barcode

import android.content.Context
import android.text.InputType
import android.util.Log
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.MethodChannel

class NativeEditText(
    context: Context,
    // This channel is used for barcode-related calls.
    private val barcodeChannel: MethodChannel,
    // This channel is used solely to send the text field flag.
    private val flagChannel: MethodChannel,
    private var previousHasData: Boolean = false
) : PlatformView {

    private val editText: EditText = EditText(context).apply {
        hint = "Enter barcode..."
        textSize = 18f
        inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_SIGNED

        isFocusableInTouchMode = true
        requestFocus()

        // Allow the soft keyboard to show.
        showSoftInputOnFocus = true

        setOnTouchListener { v, event ->
            if (event.action == MotionEvent.ACTION_DOWN) {
                showSoftInputOnFocus = true
                v.performClick()
            }
            false
        }

        // Use onEditorActionListener so that we only trigger the update when the user finishes input.
        setOnEditorActionListener { v, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE ||
                (event != null && event.keyCode == KeyEvent.KEYCODE_ENTER && event.action == KeyEvent.ACTION_DOWN)
            ) {
                handleBarcodeSubmission()
                // Use 'text' (which is equivalent to this.text) instead of editText.text.
                val hasData = text.isNotEmpty()
                Log.d("NativeEditText", "User finished input. updateFlag: $hasData")
                flagChannel.invokeMethod("updateFlag", hasData)
                true
            } else {
                false
            }
        }

        // Optionally, send an update when the field loses focus.
        setOnFocusChangeListener { v, hasFocus ->
            if (!hasFocus) {
                val hasData = text.isNotEmpty()
                Log.d("NativeEditText", "Focus lost. updateFlag: $hasData")
                flagChannel.invokeMethod("updateFlag", hasData)
            }
        }
    }

    init {
        // Set up barcode-related method calls.
        barcodeChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBarcode" -> {
                    Log.d("NativeEditText", "getBarcode called, returning: ${editText.text.toString()}")
                    result.success(editText.text.toString())
                }
                "clearText" -> {
                    Log.d("NativeEditText", "clearText called")
                    editText.text.clear()
                    result.success(null)
                }
                "clearAndFocus" -> {
                    Log.d("NativeEditText", "clearAndFocus called")
                    editText.text.clear()
                    // Here we request focus on the native EditText.
                    editText.requestFocus()
                    // Optionally, show the keyboard:
                    val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
                    imm.showSoftInput(editText, android.view.inputmethod.InputMethodManager.SHOW_IMPLICIT)
                    result.success(null)
                }
                "setBarcode" -> {
                    val barcode = call.arguments as String
                    Log.d("NativeEditText", "setBarcode called with: $barcode")
                    editText.setText(barcode)
                    editText.setSelection(barcode.length) // Move cursor to end
                    editText.requestFocus()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleBarcodeSubmission() {
        val barcode = editText.text.toString()
        Log.d("NativeEditText", "Barcode scanned: $barcode")
        barcodeChannel.invokeMethod("barcodeScanned", barcode)
        editText.text.clear()
    }

    override fun getView(): View = editText

    override fun dispose() {}
}
