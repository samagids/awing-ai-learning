import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service for running the on-device TFLite sentence embedding model.
///
/// Model: sentence-transformers/all-MiniLM-L6-v2
/// Inputs:  input_ids [1,128], attention_mask [1,128], token_type_ids [1,128]
/// Output:  [1, 128, 384] (token embeddings)
///
/// Used for comparing text similarity (e.g. pronunciation feedback).
class ModelService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Load the TFLite model from assets.
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
      _isLoaded = true;
    } catch (e) {
      // Model file not bundled yet — AI scoring disabled until model is added.
      _isLoaded = false;
    }
  }

  /// Run inference on tokenized input.
  /// Returns the [CLS] token embedding (first token, 384-dim vector)
  /// which represents the sentence meaning.
  List<double> getEmbedding(List<int> inputIds, List<int> attentionMask) {
    if (_interpreter == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    const maxSeqLen = 128;

    // Pad or truncate to maxSeqLen
    final paddedIds = _padOrTruncate(inputIds, maxSeqLen);
    final paddedMask = _padOrTruncate(attentionMask, maxSeqLen);
    final tokenTypeIds = List.filled(maxSeqLen, 0);

    // Prepare inputs as [1, 128] tensors
    final inputs = [
      [paddedIds.map((e) => e).toList()],
      [paddedMask.map((e) => e).toList()],
      [tokenTypeIds],
    ];

    // Output shape: [1, 128, 384]
    final output = List.generate(
      1,
      (_) => List.generate(maxSeqLen, (_) => List.filled(384, 0.0)),
    );

    _interpreter!.runForMultipleInputs(
      inputs.map((i) => i).toList(),
      {0: output},
    );

    // Return the [CLS] token embedding (index 0) — 384-dimensional vector
    return output[0][0];
  }

  /// Compute cosine similarity between two embeddings.
  /// Returns a value between -1 and 1 (1 = identical meaning).
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have same length');
    }
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  List<int> _padOrTruncate(List<int> list, int length) {
    if (list.length >= length) return list.sublist(0, length);
    return [...list, ...List.filled(length - list.length, 0)];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
