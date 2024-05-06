import UIKit
import Flutter
import DynamsoftBarcodeReader
import AVFoundation

class CustomCameraTexture: NSObject, FlutterTexture {
  private weak var textureRegistry: FlutterTextureRegistry?
  var textureId: Int64?
  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private let bufferQueue = DispatchQueue(label: "com.example.flutter/barcode_scan")
  private var _lastSampleBuffer: CMSampleBuffer?
  private let barcodeReader = DynamsoftBarcodeReader()
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

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

  private var flutterTextureEntry: FlutterTextureRegistry?
  private var cameraSession: AVCaptureSession?
  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private var customCameraTexture: CustomCameraTexture?
  private let CHANNEL = "barcode_scan"
  private lazy var flutterEngine = FlutterEngine(name: "my flutter engine")
  private var width = 1920
  private var height = 1080
  private var textureId: Int64?
  private var lastSampleBuffer: CMSampleBuffer?
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    guard let flutterViewController = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    flutterTextureEntry = flutterViewController.engine!.textureRegistry

    let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: flutterViewController.binaryMessenger)

    channel.setMethodCallHandler({
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
    
    // let frame = window?.frame
    // cameraPreviewLayer?.frame = frame!
    // window?.layer.insertSublayer(cameraPreviewLayer!, at: 0)

    cameraSession?.startRunning()

    result(self.customCameraTexture?.textureId)
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    self.customCameraTexture?.update(sampleBuffer: sampleBuffer)

    // let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    // let ciImage = CIImage(cvPixelBuffer: imageBuffer!)
    // let context = CIContext()
    // let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
    // let image = UIImage(cgImage: cgImage!)

    // flutterTextureEntry?.texture?.update(image.cgImage)

    // let barcodeReader = DynamsoftBarcodeReader()
    // barcodeReader.license = "LICENSE-KEY"
    // barcodeReader.barcodeFormat = EnumBarcodeFormat.ONED | EnumBarcodeFormat.PDF417 | EnumBarcodeFormat.QRCODE | EnumBarcodeFormat.DATAMATRIX
    // barcodeReader.initLicenseFromServer("https://www.dynamsoft.com/CustomerPortal/Portal/Triallicense.aspx")

    // let results = barcodeReader.decodeBuffer(image.toBuffer())
    // if results != nil {
    //   for result in results! {
    //     print(result.barcodeText)
    //   }
    // }
  }
}
