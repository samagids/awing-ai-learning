// AssetPackHandler — iOS counterpart to Android's PAD asset pack reader.
//
// Mirrors the platform-channel API exposed by MainActivity.kt
//   (channel "com.awing.learning/asset_pack")
// so that lib/services/asset_pack_service.dart can read large assets
// (audio clips, vocabulary images) on iOS the same way it does on Android.
//
// On Android these assets live in the install_time_assets PAD module.
// On iOS — which has no PAD equivalent — they're bundled directly into
// the .app bundle at build time as a folder reference (Runner.app/PADAssets/...).
// The CI workflow extracts the asset tarball into ios/Runner/PADAssets/ before
// `flutter build ios`, and Xcode includes the whole tree as resources.
//
// Methods:
//   getAssetPath(path)  -> String?   (absolute file path on disk)
//   getAssetBytes(path) -> Uint8List?
//   assetExists(path)   -> Bool
//
// `path` is the same form as Android — relative to the asset-pack root,
// e.g. "audio/boy/alphabet/a.mp3" or "images/vocabulary/hand__hand.png".

import Flutter
import Foundation

class AssetPackHandler {
    static let channelName = "com.awing.learning/asset_pack"

    /// Subdirectory inside the .app bundle where the asset tree lives.
    /// Must match the folder name added to the Xcode project as a folder
    /// reference (see project.pbxproj).
    static let bundleSubdir = "PADAssets"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            handle(call: call, result: result)
        }
    }

    private static func resolve(_ relativePath: String) -> URL? {
        // Strip leading slash if present.
        let clean = relativePath.hasPrefix("/")
            ? String(relativePath.dropFirst())
            : relativePath

        // Try Bundle.main/PADAssets/<clean>.
        let url = Bundle.main.bundleURL
            .appendingPathComponent(bundleSubdir)
            .appendingPathComponent(clean)

        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "BAD_ARGS",
                                message: "Missing 'path' argument",
                                details: nil))
            return
        }

        switch call.method {
        case "assetExists":
            result(resolve(path) != nil)

        case "getAssetPath":
            if let url = resolve(path) {
                result(url.path)
            } else {
                result(FlutterError(code: "ASSET_NOT_FOUND",
                                    message: "Asset not found: \(path)",
                                    details: nil))
            }

        case "getAssetBytes":
            if let url = resolve(path),
               let data = try? Data(contentsOf: url) {
                result(FlutterStandardTypedData(bytes: data))
            } else {
                result(FlutterError(code: "ASSET_NOT_FOUND",
                                    message: "Asset not found: \(path)",
                                    details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
