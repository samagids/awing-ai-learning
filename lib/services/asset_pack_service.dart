import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Service for accessing assets from the Play Asset Delivery install-time pack.
///
/// Large assets (audio clips, vocabulary images) are stored in the
/// `install_time_assets` Android asset pack instead of Flutter's main bundle.
/// This keeps the base AAB under the 150 MB Play Store limit.
///
/// The asset pack is installed alongside the app — no download needed.
/// Assets are accessed via a platform channel to Android's AssetManager.
class AssetPackService {
  static final AssetPackService _instance = AssetPackService._();
  factory AssetPackService() => _instance;
  AssetPackService._();

  static const _channel = MethodChannel('com.awing.learning/asset_pack');

  /// Cache of existence checks to avoid repeated platform calls.
  final Map<String, bool> _existsCache = {};

  /// Get a file system path to an asset (copies to cache dir on first access).
  /// Useful for audio players that need a file path.
  ///
  /// [assetPath] is relative to the asset pack root, e.g. "audio/boy/alphabet/a.mp3"
  Future<String?> getAssetPath(String assetPath) async {
    try {
      final path = await _channel.invokeMethod<String>(
        'getAssetPath',
        {'path': assetPath},
      );
      return path;
    } on PlatformException {
      return null;
    }
  }

  /// Get raw bytes of an asset. Useful for images (Image.memory).
  ///
  /// [assetPath] is relative to the asset pack root, e.g. "images/vocabulary/hand.png"
  Future<Uint8List?> getAssetBytes(String assetPath) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'getAssetBytes',
        {'path': assetPath},
      );
      return bytes;
    } on PlatformException {
      return null;
    }
  }

  /// Check if an asset exists in the pack.
  Future<bool> assetExists(String assetPath) async {
    if (_existsCache.containsKey(assetPath)) return _existsCache[assetPath]!;

    try {
      final exists = await _channel.invokeMethod<bool>(
        'assetExists',
        {'path': assetPath},
      ) ?? false;
      _existsCache[assetPath] = exists;
      return exists;
    } on PlatformException {
      _existsCache[assetPath] = false;
      return false;
    }
  }
}
