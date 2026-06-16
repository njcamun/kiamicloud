package com.kiamicloud.kiamicloud_mobile

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kiamicloud/device_backup",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "listUserApps" -> {
                    try {
                        result.success(listUserApps())
                    } catch (e: Exception) {
                        result.error("list_failed", e.message, null)
                    }
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("invalid_path", "APK path is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        installApkFromPath(path)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("install_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApkFromPath(apkPath: String) {
        val file = File(apkPath)
        if (!file.exists()) {
            throw IllegalArgumentException("APK not found: $apkPath")
        }
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun listUserApps(): List<Map<String, Any?>> {
        val pm = applicationContext.packageManager
        val appFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.MATCH_ALL
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_META_DATA
        }
        val installed = pm.getInstalledApplications(appFlags)
        return installed
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .filter { pm.getLaunchIntentForPackage(it.packageName) != null }
            .map { appInfo ->
                val packageInfo =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.getPackageInfo(
                            appInfo.packageName,
                            PackageManager.PackageInfoFlags.of(0),
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        pm.getPackageInfo(appInfo.packageName, 0)
                    }
                val versionCode =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        packageInfo.longVersionCode
                    } else {
                        @Suppress("DEPRECATION")
                        packageInfo.versionCode.toLong()
                    }
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "versionName" to (packageInfo.versionName ?: ""),
                    "versionCode" to versionCode,
                    "apkPath" to appInfo.sourceDir,
                    "systemApp" to false,
                    "installTimeMillis" to packageInfo.firstInstallTime,
                    "updateTimeMillis" to packageInfo.lastUpdateTime,
                )
            }
    }
}
