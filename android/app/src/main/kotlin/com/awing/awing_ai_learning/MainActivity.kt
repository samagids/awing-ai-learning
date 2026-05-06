package com.awing.awing_ai_learning

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.awing.learning/asset_pack"

    // Android 15 (SDK 35) requires apps to opt into edge-to-edge display.
    // enableEdgeToEdge() is the AndroidX-provided backwards-compatible API
    // that works on Android 5.0+ and silences the Play Console warning
    // "Edge-to-edge may not display for all users". It also handles the
    // deprecated APIs (setStatusBarColor / setNavigationBarColor) that
    // were flagged in the same warning bundle.
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAssetPath" -> {
                        // Returns a file:// path to the asset, copying to cache if needed.
                        // Install-time asset packs are merged into the app's AssetManager.
                        val assetPath = call.argument<String>("path") ?: ""
                        try {
                            val cachedFile = copyAssetToCache(assetPath)
                            result.success(cachedFile.absolutePath)
                        } catch (e: Exception) {
                            result.error("ASSET_NOT_FOUND", "Asset not found: $assetPath", e.message)
                        }
                    }
                    "getAssetBytes" -> {
                        // Returns raw bytes of the asset.
                        val assetPath = call.argument<String>("path") ?: ""
                        try {
                            val bytes = assets.open(assetPath).use { it.readBytes() }
                            result.success(bytes)
                        } catch (e: Exception) {
                            result.error("ASSET_NOT_FOUND", "Asset not found: $assetPath", e.message)
                        }
                    }
                    "assetExists" -> {
                        val assetPath = call.argument<String>("path") ?: ""
                        try {
                            assets.open(assetPath).close()
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Copy an asset from the AssetManager to the app's cache directory.
     * Returns the cached File. Skips copy if already cached.
     */
    private fun copyAssetToCache(assetPath: String): File {
        val cacheDir = File(cacheDir, "asset_pack_cache")
        val cachedFile = File(cacheDir, assetPath)

        if (cachedFile.exists()) {
            return cachedFile
        }

        cachedFile.parentFile?.mkdirs()

        assets.open(assetPath).use { input ->
            FileOutputStream(cachedFile).use { output ->
                input.copyTo(output)
            }
        }

        return cachedFile
    }
}
