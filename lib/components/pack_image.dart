import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:awing_ai_learning/services/image_service.dart';

/// Widget that loads a vocabulary image from the Play Asset Delivery pack.
///
/// Shows a placeholder while loading, and a fallback icon if the image
/// is not found. Caches loaded bytes via ImageService.
class PackImage extends StatefulWidget {
  /// Word-namespace lookup: computes imageKey(awingWord, english) internally.
  final String? awingWord;

  /// English gloss paired with `awingWord`. Required in word-namespace
  /// mode so homonyms resolve to their own illustrations. Ignored by
  /// `PackImage.path`.
  final String? english;

  /// Explicit asset pack path (e.g. for phrase_*, sentence_*, story_*
  /// namespaces where the key is already prefixed+truncated upstream).
  final String? packPath;

  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PackImage({
    super.key,
    required String this.awingWord,
    required String this.english,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : packPath = null;

  /// Load an image from a full asset pack path (bypassing imageKey).
  /// Use with ImageService.phrasePackPath / sentencePackPath / storyPackPath.
  const PackImage.path({
    super.key,
    required String this.packPath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  })  : awingWord = null,
        english = null;

  @override
  State<PackImage> createState() => _PackImageState();
}

class _PackImageState extends State<PackImage> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(PackImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.awingWord != widget.awingWord ||
        oldWidget.english != widget.english ||
        oldWidget.packPath != widget.packPath) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() { _loading = true; _error = false; });
    final Uint8List? bytes;
    if (widget.packPath != null) {
      bytes = await ImageService().getImageBytesForPath(widget.packPath!);
    } else {
      bytes = await ImageService().getImageBytes(
        widget.awingWord!,
        widget.english ?? '',
      );
    }
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _loading = false;
      _error = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // When width/height aren't explicit, fill the parent so images render
    // inside Expanded / SizedBox / etc. Without this the fallback Container
    // collapses to 0×0 and the image appears "missing".
    final fillW = widget.width ?? double.infinity;
    final fillH = widget.height ?? double.infinity;

    if (_loading) {
      return widget.placeholder ??
          Container(
            width: fillW,
            height: fillH,
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    if (_error || _bytes == null) {
      return widget.errorWidget ??
          Container(
            width: fillW,
            height: fillH,
            color: Colors.green.shade50,
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined,
                size: 48, color: Colors.green.shade300),
          );
    }

    return Image.memory(
      _bytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (_, __, ___) =>
          widget.errorWidget ??
          Container(
            width: fillW,
            height: fillH,
            color: Colors.green.shade50,
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined,
                size: 48, color: Colors.green.shade300),
          ),
    );
  }
}
