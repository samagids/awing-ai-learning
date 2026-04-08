import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  SpeechService() {
    _speech = stt.SpeechToText();
  }

  Future<void> init() async {
    await _speech.initialize();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_speech.isAvailable) return;
    await _speech.listen(onResult: (result) {
      onResult(result.recognizedWords);
    });
    _isListening = true;
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }
}
