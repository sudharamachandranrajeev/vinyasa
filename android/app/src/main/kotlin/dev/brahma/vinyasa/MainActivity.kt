package dev.brahma.vinyasa

import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Hands vinyasa:// links to Dart (lib/app/links.dart): the camera app opens
 * them when it scans a pairing QR code. Also tells Dart the device's name
 * for the pairing request and what Sentinel asks about the device, and hands
 * an update's APK to the system's installer (lib/domain/update.dart), and
 * takes still frames from a video for reading a room (lib/app/scan_media.dart). A fragment activity, which
 * local_auth needs for the app lock's fingerprint and face prompt.
 * Writes crashes outside Dart to the crash log (lib/domain/crash_log.dart).
 */
class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null
    private var pending: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        keepNativeCrashes()
        super.onCreate(savedInstanceState)
    }

    /**
     * A crash in Android's own code (a plugin, the engine) never reaches Dart:
     * write it as filesDir/crashes/crash-<utc millis>-native.txt, the format
     * Dart's crash log reads, then let Android end the app as before.
     */
    private fun keepNativeCrashes() {
        val before = Thread.getDefaultUncaughtExceptionHandler()
        if (before is NativeCrashes) return
        Thread.setDefaultUncaughtExceptionHandler(NativeCrashes(File(filesDir, "crashes"), before))
    }

    private class NativeCrashes(
        private val dir: File,
        private val before: Thread.UncaughtExceptionHandler?,
    ) : Thread.UncaughtExceptionHandler {
        override fun uncaughtException(thread: Thread, error: Throwable) {
            try {
                dir.mkdirs()
                val now = System.currentTimeMillis()
                val stack = java.io.StringWriter().also { error.printStackTrace(java.io.PrintWriter(it)) }.toString()
                File(dir, "crash-$now-native.txt").writeText(
                    listOf(
                        "Time: ${java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.ROOT).apply { timeZone = java.util.TimeZone.getTimeZone("UTC") }.format(java.util.Date(now))}",
                        "Kind: native",
                        "System: Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT}), ${Build.MANUFACTURER} ${Build.MODEL}",
                        "Thread: ${thread.name}",
                        "Error type: ${error.javaClass.name}",
                        "Error: ${error.message ?: error.javaClass.simpleName}",
                        "",
                        "Stack:",
                        stack.lines().take(150).joinToString("\n") { "  $it" },
                    ).joinToString("\n")
                )
            } catch (_: Throwable) {
            }
            before?.uncaughtException(thread, error)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pending = linkOf(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.vinyasa/device").setMethodCallHandler { call, result ->
            if (call.method == "security") result.success(securityFacts()) else result.notImplemented()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.vinyasa/update")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                if (call.method != "installApk" || path == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    // Shared from filesDir/updates (res/xml/file_paths.xml).
                    val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", File(path))
                    startActivity(
                        Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                        }
                    )
                    result.success(true)
                } catch (error: Exception) {
                    result.error("install_failed", error.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.vinyasa/frames")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                if (call.method != "frames" || path == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val count = call.argument<Int>("count") ?: 8
                val edge = call.argument<Int>("edge") ?: 1600
                val main = Handler(Looper.getMainLooper())
                Thread {
                    try {
                        val frames = framesOf(path, count, edge)
                        main.post { result.success(frames) }
                    } catch (error: Exception) {
                        main.post { result.error("frames_failed", error.message, null) }
                    }
                }.start()
            }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.vinyasa/links").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeLink" -> {
                        result.success(pending)
                        pending = null
                    }
                    "deviceName" -> result.success(deviceName())
                    else -> result.notImplemented()
                }
            }
        }
    }

    /**
     * What Sentinel reads about the device (core's device_checks.dart): whether
     * a screen lock is set, storage is encrypted, and the newest security patch.
     */
    private fun securityFacts(): Map<String, Any?> {
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val policy = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val status = policy.storageEncryptionStatus
        return mapOf(
            "screenLock" to keyguard.isDeviceSecure,
            "encrypted" to (status == DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE ||
                status == DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_PER_USER),
            "patched" to Build.VERSION.SECURITY_PATCH.takeIf { it.isNotEmpty() },
        )
    }

    /** [count] JPEG frames spread evenly through the video, at most [edge] px on the long side. */
    private fun framesOf(path: String, count: Int, edge: Int): List<ByteArray> {
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val lengthMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            return (0 until count).mapNotNull { n ->
                val atUs = lengthMs * 1000 * (2 * n + 1) / (2 * count)
                retriever.getFrameAtTime(atUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)?.let { frame ->
                    val scale = minOf(1.0, edge.toDouble() / maxOf(frame.width, frame.height))
                    val small = if (scale < 1.0) {
                        Bitmap.createScaledBitmap(frame, (frame.width * scale).toInt(), (frame.height * scale).toInt(), true)
                    } else frame
                    ByteArrayOutputStream().use { out ->
                        small.compress(Bitmap.CompressFormat.JPEG, 85, out)
                        out.toByteArray()
                    }
                }
            }.distinctBy { it.contentHashCode() }
        } finally {
            retriever.release()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        linkOf(intent)?.let { channel?.invokeMethod("link", it) }
    }

    private fun linkOf(intent: Intent?): String? =
        intent?.takeIf { it.action == Intent.ACTION_VIEW }?.data?.takeIf { it.scheme == "vinyasa" }?.toString()

    private fun deviceName(): String {
        val maker = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
        val model = Build.MODEL
        return if (model.startsWith(maker, ignoreCase = true)) model else "$maker $model"
    }
}
