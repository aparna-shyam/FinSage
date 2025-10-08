import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  // Initialize speech recognition and request permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print('❌ Microphone permission not granted');
      return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    print(_isInitialized
        ? '✅ Speech recognition initialized successfully'
        : '❌ Speech recognition initialization failed');

    return _isInitialized;
  }

  // Start listening and return final recognized text
  Future<String?> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    final completer = Completer<String?>();
    String recognizedText = '';

    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
        print('🎤 Partial text: $recognizedText');
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(recognizedText);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US', // You can change this if you want another language
    );

    // Wait for final result (or timeout)
    final finalText = await completer.future
        .timeout(const Duration(seconds: 12), onTimeout: () => recognizedText);

    await _speech.stop();

    final cleanText = finalText?.trim();
    if (cleanText == null || cleanText.isEmpty) {
      print('⚠️ No speech recognized');
      return null;
    }

    print('✅ Final recognized text: $cleanText');
    return cleanText;
  }

  void stopListening() => _speech.stop();

  bool get isListening => _speech.isListening;
}
