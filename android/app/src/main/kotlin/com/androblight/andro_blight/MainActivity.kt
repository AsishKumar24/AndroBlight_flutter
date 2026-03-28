// package com.androblight.andro_blight

// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel

// class MainActivity : FlutterActivity() {
//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         // Register DeviceSecurityPlugin for root detection
//         val channel = MethodChannel(
//             flutterEngine.dartExecutor.binaryMessenger,
//             DeviceSecurityPlugin.CHANNEL,
//         )
//         channel.setMethodCallHandler(DeviceSecurityPlugin(channel))
//     }
// }
package com.androblight.andro_blight

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DeviceSecurityPlugin.CHANNEL,
        )

        // ✅ Pass context to plugin (REQUIRED for accessing installed apps)
        channel.setMethodCallHandler(
            DeviceSecurityPlugin(this)
        )
    }
}