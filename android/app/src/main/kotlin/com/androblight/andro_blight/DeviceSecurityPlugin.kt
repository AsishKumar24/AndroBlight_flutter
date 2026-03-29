// package com.androblight.andro_blight

// import android.os.Build
// import io.flutter.plugin.common.MethodCall
// import io.flutter.plugin.common.MethodChannel
// import java.io.File

// /**
//  * DeviceSecurityPlugin
//  * Native Android root detection via MethodChannel.
//  * Channel: com.androblight.andro_blight/device_security
//  */
// class DeviceSecurityPlugin(private val channel: MethodChannel) :
//     MethodChannel.MethodCallHandler {

//     companion object {
//         const val CHANNEL = "com.androblight.andro_blight/device_security"

//         // Known root binary paths
//         private val ROOT_BINARIES = arrayOf(
//             "/system/app/Superuser.apk",
//             "/system/xbin/su",
//             "/system/bin/su",
//             "/sbin/su",
//             "/data/local/xbin/su",
//             "/data/local/bin/su",
//             "/data/local/su",
//             "/system/sd/xbin/su",
//             "/system/bin/failsafe/su",
//             "/system/xbin/busybox",
//         )

//         // Known root management app packages
//         private val ROOT_PACKAGES = arrayOf(
//             "com.noshufou.android.su",
//             "com.noshufou.android.su.elite",
//             "eu.chainfire.supersu",
//             "com.koushikdutta.superuser",
//             "com.thirdparty.superuser",
//             "com.yellowes.su",
//             "com.topjohnwu.magisk",
//             "com.kingroot.kinguser",
//             "com.kingo.root",
//             "com.smedialink.oneclickroot",
//             "com.zhiqupk.root.global",
//             "com.alephzain.framaroot",
//         )
//     }

//     override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
//         when (call.method) {
//             "checkRootStatus" -> {
//                 val indicators = mutableListOf<String>()
//                 var isRooted = false

//                 // 1. Check for su binaries
//                 for (path in ROOT_BINARIES) {
//                     if (File(path).exists()) {
//                         indicators.add("Found: $path")
//                         isRooted = true
//                     }
//                 }

//                 // 2. Check build tags for test-keys
//                 val buildTags = Build.TAGS
//                 if (buildTags != null && buildTags.contains("test-keys")) {
//                     indicators.add("Build signed with test-keys")
//                     isRooted = true
//                 }

//                 // 3. Check ro.debuggable system property
//                 try {
//                     val process = Runtime.getRuntime().exec(arrayOf("/system/bin/getprop", "ro.debuggable"))
//                     val debuggable = process.inputStream.bufferedReader().readLine()
//                     if (debuggable == "1") {
//                         indicators.add("ro.debuggable=1")
//                         isRooted = true
//                     }
//                 } catch (_: Exception) {}

//                 // 4. Try executing 'su' command
//                 try {
//                     Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
//                     indicators.add("su command executable")
//                     isRooted = true
//                 } catch (_: Exception) {}

//                 result.success(
//                     mapOf(
//                         "is_rooted" to isRooted,
//                         "device_model" to "${Build.MANUFACTURER} ${Build.MODEL}",
//                         "android_version" to Build.VERSION.RELEASE,
//                         "root_indicators" to indicators,
//                     )
//                 )
//             }
//             else -> result.notImplemented()
//         }
//     }
// }
package com.androblight.andro_blight

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 🔥 DeviceSecurityPlugin
 *
 * Handles:
 * 1. Root detection (existing)
 * 2. ✅ Installed apps retrieval (NEW FEATURE)
 *
 * MethodChannel: com.androblight.andro_blight/device_security
 *
 * NEW METHOD ADDED:
 * - "getInstalledPackages"
 *   → Play Store, APK/package-installer installs, and user apps with no installer (sideload)
 */
class DeviceSecurityPlugin(private val context: Context) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.androblight.andro_blight/device_security"

        private const val PLAY_INSTALLER = "com.android.vending"

        /** System UI used to install APK files (sideload). */
        private val APK_INSTALLERS = setOf(
            "com.android.packageinstaller",
            "com.google.android.packageinstaller",
            "com.samsung.android.packageinstaller",
        )

        private val ROOT_BINARIES = arrayOf(
            "/system/app/Superuser.apk",
            "/system/xbin/su",
            "/system/bin/su",
            "/sbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/data/local/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/system/xbin/busybox",
        )

        fun installerFor(pm: PackageManager, pkg: String): String? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    pm.getInstallSourceInfo(pkg).installingPackageName
                } catch (_: Exception) {
                    null
                }
            } else {
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(pkg)
            }

        /** Play Store, package-installer APKs, or non-system apps with unknown installer (typical sideload). */
        fun isPlayOrApkInstall(pm: PackageManager, app: ApplicationInfo): Boolean {
            val inst = installerFor(pm, app.packageName)
            if (inst == PLAY_INSTALLER) return true
            if (inst != null && inst in APK_INSTALLERS) return true
            val userApp = (app.flags and ApplicationInfo.FLAG_SYSTEM) == 0
            if (inst == null && userApp) return true
            return false
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            // ✅ Existing Root Detection
            "checkRootStatus" -> {
                val indicators = mutableListOf<String>()
                var isRooted = false

                for (path in ROOT_BINARIES) {
                    if (File(path).exists()) {
                        indicators.add("Found: $path")
                        isRooted = true
                    }
                }

                val buildTags = Build.TAGS
                if (buildTags != null && buildTags.contains("test-keys")) {
                    indicators.add("Build signed with test-keys")
                    isRooted = true
                }

                try {
                    val process = Runtime.getRuntime()
                        .exec(arrayOf("/system/bin/getprop", "ro.debuggable"))
                    val debuggable = process.inputStream.bufferedReader().readLine()
                    if (debuggable == "1") {
                        indicators.add("ro.debuggable=1")
                        isRooted = true
                    }
                } catch (_: Exception) {}

                try {
                    Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
                    indicators.add("su command executable")
                    isRooted = true
                } catch (_: Exception) {}

                result.success(
                    mapOf(
                        "is_rooted" to isRooted,
                        "device_model" to "${Build.MANUFACTURER} ${Build.MODEL}",
                        "android_version" to Build.VERSION.RELEASE,
                        "root_indicators" to indicators,
                    )
                )
            }

            // ✅ NEW: Get Installed Apps
            "getInstalledPackages" -> {
                try {
                    val pm = context.packageManager
                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        PackageManager.MATCH_ALL
                    } else 0
                    val names = pm.getInstalledApplications(flags)
                        .asSequence()
                        .filter { isPlayOrApkInstall(pm, it) }
                        .map { it.packageName }
                        .sorted()
                        .toList()
                    result.success(names)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            /** Open system UI to allow installing APKs from this app (Android 8+). */
            "openInstallPermissionSettings" -> {
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:${context.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        context.startActivity(intent)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

            /** Launch package installer for a local APK path (must stay under FileProvider paths). */
            "installApk" -> {
                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "path required", null)
                    return
                }
                try {
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("NOT_FOUND", "APK file not found", null)
                        return
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        if (!context.packageManager.canRequestPackageInstalls()) {
                            result.error(
                                "INSTALL_PERMISSION_REQUIRED",
                                "Allow installs from this app in Settings",
                                mapOf("package" to context.packageName),
                            )
                            return
                        }
                    }
                    val authority = "${context.packageName}.fileprovider"
                    val uri = FileProvider.getUriForFile(context, authority, file)
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INSTALL_FAILED", e.message ?: "install failed", null)
                }
            }

            else -> result.notImplemented()
        }
    }
}