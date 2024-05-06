import UIKit
import Flutter
import DynamsoftBarcodeReader
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  private var flutterTextureRegistry: FlutterTextureRegistry?
  private var cameraSession: AVCaptureSession?
  private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
  private let CHANNEL = "barcode_scan"
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
