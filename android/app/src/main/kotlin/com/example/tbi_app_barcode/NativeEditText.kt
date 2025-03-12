package com.example.tbi_app_barcode

import android.content.Context
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher
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

        showSoftInputOnFocus = false

        setOnTouchListener { v, event ->
            if (event.action == MotionEvent.ACTION_DOWN) {
                showSoftInputOnFocus = true
                v.performClick()
            }
            false
        }

        setOnEditorActionListener { v, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE ||
                (event != null && event.keyCode == KeyEvent.KEYCODE_ENTER && event.action == KeyEvent.ACTION_DOWN)
            ) {
                handleBarcodeSubmission()
                true
            } else {
                false
            }
        }

        // Add a TextWatcher to monitor the text field content.

        addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                // Determine whether there is data in the text field.
                val hasData = s?.isNotEmpty() == true
                // Only send the update if the state has changed.
                if (hasData != previousHasData) {
                    previousHasData = hasData
                    flagChannel.invokeMethod("updateFlag", hasData)
                }
            }

            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) { /* Not needed */ }

            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { /* Not needed */ }
        })
    }

    init {
        // Set up barcode-related method calls.
        barcodeChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBarcode" -> result.success(editText.text.toString())
                "clearText" -> {
                    editText.text.clear()
                    result.success(null)
                }
                "clearAndFocus" -> {
                    editText.text.clear()
                    editText.requestFocus()
                    result.success(null)
                }
                "setBarcode" -> {
                    val barcode = call.arguments as String
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
        android.util.Log.d("NativeEditText", "Barcode scanned: $barcode")
        barcodeChannel.invokeMethod("barcodeScanned", barcode)
        editText.text.clear()
    }

    override fun getView(): View = editText

    override fun dispose() {}
}
