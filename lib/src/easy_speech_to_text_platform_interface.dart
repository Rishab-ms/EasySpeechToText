import 'dart:async';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../speech_engine.dart';
import '../locale_name.dart';
import 'easy_speech_to_text_method_channel.dart';

/// Platform interface for speech-to-text functionality.
abstract class EasySpeechToTextPlatform extends PlatformInterface {
  /// Constructs an EasySpeechToTextPlatform.
  EasySpeechToTextPlatform() : super(token: _token);

  static final Object _token = Object();

  static EasySpeechToTextPlatform _instance = MethodChannelEasySpeechToText();

  /// The default instance of [EasySpeechToTextPlatform] to use.
  ///
  /// Defaults to [MethodChannelEasySpeechToText].
  static EasySpeechToTextPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EasySpeechToTextPlatform] when
  /// they register themselves.
  static set instance(EasySpeechToTextPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream to receive speech recognition events.
  Stream<dynamic> get onSpeechResult {
    throw UnimplementedError('onSpeechResult has not been implemented.');
  }

  /// Initializes the speech recognition engine.
  ///
  /// [engine]: Selects the speech recognition engine.
  /// [options]: Additional configuration options for the engine.
  Future<void> initialize({
    required SpeechEngine engine,
    Map<String, dynamic>? options,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Checks if the application has speech recognition and microphone permissions.
  Future<bool> hasPermission() {
    throw UnimplementedError('hasPermission() has not been implemented.');
  }

  /// Requests speech recognition and microphone permissions from the user.
  Future<bool> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Starts speech recognition.
  ///
  /// [localeId]: Specifies the language.
  /// [customWords]: List of custom words to improve recognition accuracy.
  /// [partialResults]: Whether to receive partial results.
  /// [pauseFor]: Duration to automatically stop recognition after silence.
  Future<void> startListening({
    String? localeId,
    List<String>? customWords,
    bool partialResults = true,
    Duration? pauseFor,
  }) {
    throw UnimplementedError('startListening() has not been implemented.');
  }

  /// Stops speech recognition and returns the final result.
  Future<void> stopListening() {
    throw UnimplementedError('stopListening() has not been implemented.');
  }

  /// Cancels speech recognition without returning a result.
  Future<void> cancelListening() {
    throw UnimplementedError('cancelListening() has not been implemented.');
  }

  /// Transcribes an audio file to text.
  ///
  /// [filePath]: Path to the audio file.
  /// [localeId]: Specifies the language.
  /// [customWords]: List of custom words to improve recognition accuracy.
  Future<String?> transcribe({
    required String filePath,
    String? localeId,
    List<String>? customWords,
  }) {
    throw UnimplementedError('transcribe() has not been implemented.');
  }

  /// Sets a global custom words list to improve recognition accuracy.
  ///
  /// [words]: List of custom words.
  void setCustomWords(List<String> words) {
    throw UnimplementedError('setCustomWords() has not been implemented.');
  }

  /// Retrieves the list of supported languages by the speech recognition engine.
  Future<List<LocaleName>> getAvailableLanguages() {
    throw UnimplementedError(
        'getAvailableLanguages() has not been implemented.');
  }
}
