import 'dart:async';
import '../speech_engine.dart';
import '../locale_name.dart';
import 'easy_speech_to_text_platform_interface.dart';

/// Core class for speech-to-text functionality.
class EasySpeechToText {
  // Private singleton instance.
  static final EasySpeechToText _instance = EasySpeechToText._internal();

  // Factory constructor returns the singleton instance.
  factory EasySpeechToText() => _instance;

  // Private constructor.
  EasySpeechToText._internal();

  // Stream to receive speech recognition events.
  Stream<dynamic>? _eventStream;

  // Stream subscription to manage event stream.
  StreamSubscription<dynamic>? _subscription;

  /// Initializes the speech recognition engine.
  ///
  /// [engine]: Selects the speech recognition engine. Defaults to [SpeechEngine.native].
  /// [options]: Additional configuration options for the engine.
  ///
  /// Throws an [Exception] if initialization fails.
  Future<void> initialize({
    SpeechEngine engine = SpeechEngine.native,
    Map<String, dynamic>? options,
  }) {
    return EasySpeechToTextPlatform.instance.initialize(
      engine: engine,
      options: options,
    );
  }

  /// Checks if the application has speech recognition and microphone permissions.
  ///
  /// Returns `true` if permissions are granted, `false` otherwise.
  Future<bool> hasPermission() {
    return EasySpeechToTextPlatform.instance.hasPermission();
  }

  /// Requests speech recognition and microphone permissions from the user.
  ///
  /// Returns `true` if permissions are granted, `false` otherwise.
  Future<bool> requestPermission() {
    return EasySpeechToTextPlatform.instance.requestPermission();
  }

  /// Starts speech recognition.
  ///
  /// [localeId]: Specifies the language (e.g., "en_US").
  /// [customWords]: List of custom words to improve recognition accuracy.
  /// [partialResults]: Whether to receive partial results. Defaults to `true`.
  /// [pauseFor]: Duration to automatically stop recognition after silence.
  /// [onResult]: Callback function to receive recognition results.
  /// [onError]: Callback function to receive error messages.
  ///
  /// Throws an [Exception] if the speech engine is not initialized.
  Future<void> startListening({
    String? localeId,
    List<String>? customWords,
    bool partialResults = true,
    Duration? pauseFor,
    required Function(String text) onResult,
    Function(String error)? onError,
  }) {
    _listenToEvents(onResult, onError);
    return EasySpeechToTextPlatform.instance.startListening(
      localeId: localeId,
      customWords: customWords,
      partialResults: partialResults,
      pauseFor: pauseFor,
    );
  }

  /// Stops speech recognition and returns the final result.
  Future<void> stopListening() async {
    await _subscription?.cancel(); // Cancel the subscription when stopping
    return EasySpeechToTextPlatform.instance.stopListening();
  }

  /// Cancels speech recognition without returning a result.
  Future<void> cancelListening() async {
    await _subscription?.cancel(); // Cancel the subscription when cancelling
    return EasySpeechToTextPlatform.instance.cancelListening();
  }

  /// Transcribes an audio file to text.
  ///
  /// [filePath]: Path to the audio file.
  /// [localeId]: Specifies the language.
  /// [customWords]: List of custom words to improve recognition accuracy.
  ///
  /// Returns the transcribed text.
  ///
  /// Throws an [Exception] if the speech engine is not initialized.
  Future<String?> transcribe({
    required String filePath,
    String? localeId,
    List<String>? customWords,
  }) {
    return EasySpeechToTextPlatform.instance.transcribe(
      filePath: filePath,
      localeId: localeId,
      customWords: customWords,
    );
  }

  /// Sets a global custom words list to improve recognition accuracy.
  ///
  /// [words]: List of custom words.
  void setCustomWords(List<String> words) {
    EasySpeechToTextPlatform.instance.setCustomWords(words);
  }

  /// Retrieves the list of supported languages by the speech recognition engine.
  ///
  /// Returns a list of [LocaleName].
  Future<List<LocaleName>> getAvailableLanguages() {
    return EasySpeechToTextPlatform.instance.getAvailableLanguages();
  }

  // Private method to listen to speech recognition events.
  void _listenToEvents(
    Function(String text) onResult,
    Function(String error)? onError,
  ) {
    _eventStream ??= EasySpeechToTextPlatform.instance.onSpeechResult;
    _subscription = _eventStream!.listen((event) {
      final Map<String, dynamic> result = Map<String, dynamic>.from(event);
      if (result['error'] != null && onError != null) {
        onError(result['error']);
      } else if (result['result'] != null) {
        onResult(result['result']);
      }
    });
  }
}
