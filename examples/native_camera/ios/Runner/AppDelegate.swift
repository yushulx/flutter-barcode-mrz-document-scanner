import UIKit
import Flutter
import DynamsoftBarcodeReaderBundle
import AVFoundation

class CustomCameraTexture: NSObject, FlutterTexture {
  private weak var textureRegistry: FlutterTextureRegistry?
  var textureId: Int64?
  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private let bufferQueue = DispatchQueue(label: "com.example.flutter/barcode_scan")
  private var _lastSampleBuffer: CMSampleBuffer?
  private var customCameraTexture: CustomCameraTexture?

  private var lastSampleBuffer: CMSampleBuffer? {
    get {
      var result: CMSampleBuffer?
      bufferQueue.sync {
        result = _lastSampleBuffer
      }
      return result
    }
    set {
      bufferQueue.sync {
        _lastSampleBuffer = newValue
      }
    }
  }

  init(cameraPreviewLayer: AVCaptureVideoPreviewLayer, registry: FlutterTextureRegistry) {
    self.cameraPreviewLayer = cameraPreviewLayer
    self.textureRegistry = registry
    super.init()
    self.textureId = registry.register(self)
  }

  func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
    guard let sampleBuffer = lastSampleBuffer, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return nil
    }

    return Unmanaged.passRetained(pixelBuffer)
  }

  func update(sampleBuffer: CMSampleBuffer) {
    lastSampleBuffer = sampleBuffer
    textureRegistry?.textureFrameAvailable(textureId!)
  }

  deinit {
    if let textureId = textureId {
      textureRegistry?.unregisterTexture(textureId)
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, LicenseVerificationListener {

  private var flutterTextureEntry: FlutterTextureRegistry?
  private var cameraSession: AVCaptureSession?
  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private var customCameraTexture: CustomCameraTexture?
  private let CHANNEL = "barcode_scan"
  private var width = 1920
  private var height = 1080
  private var isProcessing = false
  private var channel: FlutterMethodChannel?
  private let cvr = CaptureVisionRouter()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    LicenseManager.initLicense("DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==", verificationDelegate: self)

    GeneratedPluginRegistrant.register(with: self)

    guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    flutterTextureEntry = flutterViewController.engine.textureRegistry

    channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: flutterViewController.binaryMessenger)
    channel?.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "startCamera" {
        self.startCamera(result: result)
      } else if call.method == "getPreviewWidth" {
        result(self.width)
      } else if call.method == "getPreviewHeight" {
        result(self.height)
      }

      else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func onLicenseVerified(_ isSuccess: Bool, error: Error?) {
    if isSuccess {
      print("License verification passed")
    } else {
      print("License verification failed: \(error?.localizedDescription ?? "Unknown error")")
    }
  }

  private func startCamera(result: @escaping FlutterResult) {
    if cameraSession != nil {
      result(self.customCameraTexture?.textureId)
      return
    }

    cameraSession = AVCaptureSession()
    cameraSession?.sessionPreset = .hd1920x1080

    guard let backCamera = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: backCamera) else {
      result(FlutterError(code: "no_camera", message: "No camera available", details: nil))
      return
    }

    cameraSession?.addInput(input)
    cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraSession!)
    cameraPreviewLayer?.videoGravity = .resizeAspectFill

    let cameraOutput = AVCaptureVideoDataOutput()
    cameraOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    cameraOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_queue"))
    cameraSession?.addOutput(cameraOutput)

    self.customCameraTexture = CustomCameraTexture(cameraPreviewLayer: cameraPreviewLayer!, registry: flutterTextureEntry!)
    cameraSession?.startRunning()

    result(self.customCameraTexture?.textureId)
  }

  func currentVideoOrientation() -> AVCaptureVideoOrientation {
    switch UIDevice.current.orientation {
    case .portrait:
      return .portrait
    case .portraitUpsideDown:
      return .portraitUpsideDown
    case .landscapeLeft:
      return .landscapeRight
    case .landscapeRight:
      return .landscapeLeft
    default:
      return .portrait
    }
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    if connection.isVideoOrientationSupported {
      connection.videoOrientation = currentVideoOrientation()
    }
    self.customCameraTexture?.update(sampleBuffer: sampleBuffer)

    if !isProcessing {
      isProcessing = true
      DispatchQueue.global(qos: .background).async {
        self.processImage(sampleBuffer)
        self.isProcessing = false
      }
    }
  }

  func processImage(_ sampleBuffer: CMSampleBuffer) {
    let imageBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
    let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
    let bufferSize = CVPixelBufferGetDataSize(imageBuffer)
    let width = CVPixelBufferGetWidth(imageBuffer)
    let height = CVPixelBufferGetHeight(imageBuffer)
    let bpr = CVPixelBufferGetBytesPerRow(imageBuffer)
    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
    let buffer = Data(bytes: baseAddress!, count: bufferSize)

    let imageData = ImageData()
    imageData.bytes = buffer
    imageData.width = UInt(width)
    imageData.height = UInt(height)
    imageData.stride = UInt(bpr)
    imageData.format = .ARGB8888
    imageData.orientation = 0

    let capturedResult = cvr.captureFromBuffer(imageData, templateName: PresetTemplate.readBarcodes.rawValue)
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onBarcodeDetected", arguments: self.wrapResults(capturedResult: capturedResult))
    }
  }

  func wrapResults(capturedResult: CapturedResult?) -> NSArray {
    let outResults = NSMutableArray(capacity: 8)
    guard let items = capturedResult?.items else {
      return outResults
    }
    for item in items {
      if item.type != CapturedResultItemType.barcode {
        continue
      }
      let barcodeItem = item as! BarcodeResultItem
      let subDic = NSMutableDictionary(capacity: 11)
      subDic.setObject(barcodeItem.formatString, forKey: "format" as NSCopying)
      let points = barcodeItem.location.points
      subDic.setObject(Int(points[0].cgPointValue.x), forKey: "x1" as NSCopying)
      subDic.setObject(Int(points[0].cgPointValue.y), forKey: "y1" as NSCopying)
      subDic.setObject(Int(points[1].cgPointValue.x), forKey: "x2" as NSCopying)
      subDic.setObject(Int(points[1].cgPointValue.y), forKey: "y2" as NSCopying)
      subDic.setObject(Int(points[2].cgPointValue.x), forKey: "x3" as NSCopying)
      subDic.setObject(Int(points[2].cgPointValue.y), forKey: "y3" as NSCopying)
      subDic.setObject(Int(points[3].cgPointValue.x), forKey: "x4" as NSCopying)
      subDic.setObject(Int(points[3].cgPointValue.y), forKey: "y4" as NSCopying)
      subDic.setObject(barcodeItem.angle, forKey: "angle" as NSCopying)
      subDic.setObject(barcodeItem.bytes, forKey: "barcodeBytes" as NSCopying)
      outResults.add(subDic)
    }

    return outResults
  }
}