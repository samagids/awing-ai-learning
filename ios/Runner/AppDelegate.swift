import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // CRITICAL: configure the [DEFAULT] FirebaseApp synchronously here,
    // BEFORE super.application(...) and BEFORE Flutter's Dart code runs.
    // Without this call, Dart-side Firebase.initializeApp() throws
    // "[core/no-app] No Firebase App '[DEFAULT]' has been created" on
    // iOS — even though firebase_core's plugin is registered later in
    // didInitializeImplicitFlutterEngine — because the FlutterImplicit-
    // EngineDelegate pattern doesn't bootstrap [FIRApp configure] from
    // GoogleService-Info.plist the way the older AppDelegate pattern did.
    // App Store Connect rejected v1.11.0+39's auth flow because of this.
    FirebaseApp.configure()
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
