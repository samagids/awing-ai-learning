import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register the asset-pack platform channel — iOS counterpart to
    // Android's MainActivity.kt PAD reader. Reads bundled assets out of
    // Runner.app/PADAssets/ via Bundle.main. Channel name and methods
    // match com.awing.learning/asset_pack on Android exactly.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AssetPackHandler") {
      AssetPackHandler.register(with: registrar.messenger())
    }
  }
}
