package com.example.nativecamera

import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.view.Surface
import android.widget.Toast
import androidx.camera.core.AspectRatio
import androidx.camera.core.Camera
import androidx.camera.core.CameraInfo
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraState
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.dynamsoft.dbr.BarcodeReader
import com.dynamsoft.dbr.EnumImagePixelFormat
import com.dynamsoft.dbr.TextResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

typealias ResultListener = (results: List<Map<String, Any>>) -> Unit

class MainActivity : FlutterActivity(), ActivityAware {
    private val CAMERA_REQUEST_CODE = 101
    private val CHANNEL = "barcode_scan"
    private lateinit var channel: MethodChannel
    private lateinit var flutterTextureEntry: SurfaceTextureEntry
    private lateinit var flutterEngine: FlutterEngine
    private var lensFacing: Int = CameraSelector.LENS_FACING_BACK
    private var preview: Preview? = null
    private var imageAnalyzer: ImageAnalysis? = null
    private lateinit var cameraExecutor: ExecutorService
    private var camera: Camera? = null
    private var previewWidth = 1280
    private var previewHeight = 720

    fun setLicense(license: String?) {
        BarcodeReader.initLicense(license) { isSuccessful, e ->
            if (isSuccessful) {
                // The license verification was successful.
            } else {
                // The license verification failed. e contains the error information.
            }
        }
    }

    override fun onDetachedFromActivity() {
        flutterTextureEntry?.release()
        cameraExecutor.shutdown()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {}

    private fun requestCameraPermission() {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.CAMERA) !=
                        PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                    this,
                    arrayOf(android.Manifest.permission.CAMERA),
                    CAMERA_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ) {
        when (requestCode) {
            CAMERA_REQUEST_CODE -> {
                if (grantResults.isNotEmpty() &&
                                grantResults[0] == PackageManager.PERMISSION_GRANTED
                ) {} else {
                    Toast.makeText(
                                    this,
                                    "Camera permission is required to use this feature",
                                    Toast.LENGTH_SHORT
                            )
                            .show()
                }
            }
            else -> super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    private fun aspectRatio(width: Int, height: Int): Int {
        var previewRatio = Math.max(width, height).toDouble() / Math.min(width, height)
        if (Math.abs(previewRatio - 4.0 / 3.0) <= Math.abs(previewRatio - 16.0 / 9.0)) {
            return AspectRatio.RATIO_4_3
        }
        return AspectRatio.RATIO_16_9
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        setLicense(
                "DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ=="
        )
        cameraExecutor = Executors.newSingleThreadExecutor()
        super.configureFlutterEngine(flutterEngine)
        this.flutterEngine = flutterEngine

        requestCameraPermission()

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
            if (call.method == "startCamera") {
                startCamera(result)
            } else if (call.method == "getAspectRatio") {
                result.success(getAspectRatio())
            } else if (call.method == "getPreviewWidth") {
                result.success(getPreviewWidth())
            } else if (call.method == "getPreviewHeight") {
                result.success(getPreviewHeight())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startCamera(result: MethodChannel.Result) {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener(
                {
                    val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()
                    bindCamera(cameraProvider, result)
                },
                ContextCompat.getMainExecutor(this)
        )
    }

    private fun getAspectRatio(): Double {
        return previewWidth.toDouble() / previewHeight.toDouble()
    }

    private fun getPreviewWidth(): Double {
        return previewWidth.toDouble()
    }

    private fun getPreviewHeight(): Double {
        return previewHeight.toDouble()
    }

    private fun bindCamera(provider: ProcessCameraProvider, result: MethodChannel.Result) {
        // Get screen metrics used to setup camera for full screen resolution
        val metrics = windowManager.getCurrentWindowMetrics().bounds

        val screenAspectRatio = aspectRatio(metrics.width(), metrics.height())

        val rotation = display!!.rotation

        // CameraProvider
        val cameraProvider =
                provider ?: throw IllegalStateException("Camera initialization failed.")

        // CameraSelector
        val cameraSelector = CameraSelector.Builder().requireLensFacing(lensFacing).build()

        flutterTextureEntry = flutterEngine.renderer.createSurfaceTexture()

        // Preview
        preview =
                Preview.Builder()
                        .setTargetAspectRatio(screenAspectRatio)
                        .setTargetRotation(rotation)
                        .build()
                        .also {
                            it.setSurfaceProvider { request ->
                                val surfaceTexture =
                                        flutterTextureEntry?.surfaceTexture().apply {
                                            this?.setDefaultBufferSize(previewWidth, previewHeight)
                                        }
                                val surface = Surface(surfaceTexture)

                                request.provideSurface(
                                        surface,
                                        ContextCompat.getMainExecutor(this)
                                ) {}
                            }
                        }

        imageAnalyzer =
                ImageAnalysis.Builder()
                        .setTargetAspectRatio(screenAspectRatio)
                        .setTargetRotation(rotation)
                        .build()
                        .also {
                            it.setAnalyzer(
                                    cameraExecutor,
                                    ImageAnalyzer { results ->
                                        Handler(Looper.getMainLooper()).post {
                                            // UI-related operations
                                            channel.invokeMethod("onBarcodeDetected", results)
                                        }
                                    }
                            )
                        }

        if (camera != null) {
            // Must remove observers from the previous camera instance
            removeCameraStateObservers(camera!!.cameraInfo)
        }

        try {
            cameraProvider.unbindAll() // Unbind use cases before rebinding
            camera = cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalyzer)
            observeCameraState(camera?.cameraInfo!!)
            result.success(flutterTextureEntry?.id())
        } catch (e: Exception) {
            result.error("CAMERA_INIT_FAILED", "Failed to initialize camera: ${e.message}", null)
        }
    }

    private fun removeCameraStateObservers(cameraInfo: CameraInfo) {
        cameraInfo.cameraState.removeObservers(this)
    }

    // https://github.com/android/camera-samples/tree/main/CameraXBasic
    private fun observeCameraState(cameraInfo: CameraInfo) {
        cameraInfo.cameraState.observe(this) { cameraState ->
            run {
                when (cameraState.type) {
                    CameraState.Type.PENDING_OPEN -> {
                        // Ask the user to close other camera apps
                        Toast.makeText(context, "CameraState: Pending Open", Toast.LENGTH_SHORT)
                                .show()
                    }
                    CameraState.Type.OPENING -> {
                        // Show the Camera UI
                        Toast.makeText(context, "CameraState: Opening", Toast.LENGTH_SHORT).show()
                    }
                    CameraState.Type.OPEN -> {
                        // Setup Camera resources and begin processing
                        Toast.makeText(context, "CameraState: Open", Toast.LENGTH_SHORT).show()
                    }
                    CameraState.Type.CLOSING -> {
                        // Close camera UI
                        Toast.makeText(context, "CameraState: Closing", Toast.LENGTH_SHORT).show()
                    }
                    CameraState.Type.CLOSED -> {
                        // Free camera resources
                        Toast.makeText(context, "CameraState: Closed", Toast.LENGTH_SHORT).show()
                    }
                }
            }

            cameraState.error?.let { error ->
                when (error.code) {
                    // Open errors
                    CameraState.ERROR_STREAM_CONFIG -> {
                        // Make sure to setup the use cases properly
                        Toast.makeText(context, "Stream config error", Toast.LENGTH_SHORT).show()
                    }
                    // Opening errors
                    CameraState.ERROR_CAMERA_IN_USE -> {
                        // Close the camera or ask user to close another camera app that's using the
                        // camera
                        Toast.makeText(context, "Camera in use", Toast.LENGTH_SHORT).show()
                    }
                    CameraState.ERROR_MAX_CAMERAS_IN_USE -> {
                        // Close another open camera in the app, or ask the user to close another
                        // camera app that's using the camera
                        Toast.makeText(context, "Max cameras in use", Toast.LENGTH_SHORT).show()
                    }
                    CameraState.ERROR_OTHER_RECOVERABLE_ERROR -> {
                        Toast.makeText(context, "Other recoverable error", Toast.LENGTH_SHORT)
                                .show()
                    }
                    // Closing errors
                    CameraState.ERROR_CAMERA_DISABLED -> {
                        // Ask the user to enable the device's cameras
                        Toast.makeText(context, "Camera disabled", Toast.LENGTH_SHORT).show()
                    }
                    CameraState.ERROR_CAMERA_FATAL_ERROR -> {
                        // Ask the user to reboot the device to restore camera function
                        Toast.makeText(context, "Fatal error", Toast.LENGTH_SHORT).show()
                    }
                    // Closed errors
                    CameraState.ERROR_DO_NOT_DISTURB_MODE_ENABLED -> {
                        // Ask the user to disable the "Do Not Disturb" mode, then reopen the camera
                        Toast.makeText(context, "Do not disturb mode enabled", Toast.LENGTH_SHORT)
                                .show()
                    }
                }
            }
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(p0: ActivityPluginBinding) {}

    private class ImageAnalyzer(listener: ResultListener? = null) : ImageAnalysis.Analyzer {
        private val mBarcodeReader: BarcodeReader = BarcodeReader()
        private val listeners = ArrayList<ResultListener>().apply { listener?.let { add(it) } }

        private fun ByteBuffer.toByteArray(): ByteArray {
            rewind() // Rewind the buffer to zero
            val data = ByteArray(remaining())
            get(data) // Copy the buffer into a byte array
            return data // Return the byte array
        }

        override fun analyze(image: ImageProxy) {
            // If there are no listeners attached, we don't need to perform analysis
            if (listeners.isEmpty()) {
                image.close()
                return
            }

            // Since format in ImageAnalysis is YUV, image.planes[0] contains the luminance plane
            val buffer = image.planes[0].buffer
            val stride = image.planes[0].rowStride

            // Extract image data from callback object
            val data = buffer.toByteArray()

            // Read barcode from image data
            val results =
                    mBarcodeReader?.decodeBuffer(
                            data,
                            image.width,
                            image.height,
                            stride,
                            EnumImagePixelFormat.IPF_NV21
                    )
            // Call all listeners with new value
            listeners.forEach { it(wrapResults(results)) }

            image.close()
        }

        private fun wrapResults(results: Array<TextResult>?): List<Map<String, Any>> {
            val out = mutableListOf<Map<String, Any>>()
            if (results != null) {
                for (result in results) {
                    val data: MutableMap<String, Any> = HashMap()
                    data["format"] = result.barcodeFormatString
                    // data.put("text", result.barcodeText);
                    data["x1"] = result.localizationResult.resultPoints[0].x
                    data["y1"] = result.localizationResult.resultPoints[0].y
                    data["x2"] = result.localizationResult.resultPoints[1].x
                    data["y2"] = result.localizationResult.resultPoints[1].y
                    data["x3"] = result.localizationResult.resultPoints[2].x
                    data["y3"] = result.localizationResult.resultPoints[2].y
                    data["x4"] = result.localizationResult.resultPoints[3].x
                    data["y4"] = result.localizationResult.resultPoints[3].y
                    data["angle"] = result.localizationResult.angle
                    data["barcodeBytes"] = result.barcodeBytes
                    out.add(data)
                }
            }
            return out
        }
    }
}
