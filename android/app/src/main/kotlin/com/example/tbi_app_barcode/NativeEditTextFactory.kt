package com.example.tbi_app_barcode

import android.content.Context
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.common.MethodChannel

class NativeEditTextFactory(
    private val barcodeChannel: MethodChannel,
    private val flagChannel: MethodChannel
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        return NativeEditText(context, barcodeChannel, flagChannel)
    }
}
