import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import '../speech_engine.dart';
import '../locale_name.dart';
import 'easy_speech_to_text_platform_interface.dart';
import 'easy_speech_to_text_exceptions.dart';

/// An implementation of [EasySpeechToTextPlatform] that uses method channels.
class MethodChannelEasySpeechToText extends EasySpeechToTextPlatform {
  // Method channel used to communicate with the native platform.
  static const MethodChannel _methodChannel =
      MethodChannel('easy_speech_to_text/methods');

  // Event channel used to receive speech recognition events from the native platform.
  static const EventChannel _eventChannel =
      EventChannel('easy_speech_to_text/events');

  // Stream to receive speech recognition events.
  Stream<dynamic>? _eventStream;

  // Indicates whether the speech engine has been initialized.
  bool _isInitialized = false;

  // Current speech recognition engine.
  SpeechEngine _currentEngine = SpeechEngine.native;

  // List of custom words.
  List<String> _customWords = [];

  @override
  Stream<dynamic> get onSpeechResult {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
    return _eventStream!;
  }

  @override
  Future<void> initialize({
    required SpeechEngine engine,
    Map<String, dynamic>? options,
  }) async {
    _currentEngine = engine;
    try {
      await _methodChannel.invokeMethod('initialize', {
        'engine': engine.index,
        'options': options,
      });
      _isInitialized = true;
    } on PlatformException catch (e) {
      _isInitialized = false;
      throw EasySpeechToTextException(
          'Failed to initialize speech recognition: ${e.message}',
          code: e.code);
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final bool hasPermission =
          await _methodChannel.invokeMethod('hasPermission', {
        'engine': _currentEngine.index,
      });
      return hasPermission;
    } on PlatformException catch (e) {
      throw EasySpeechToTextException(
          'Failed to check permissions: ${e.message}',
          code: e.code);
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final bool granted =
          await _methodChannel.invokeMethod('requestPermission', {
        'engine': _currentEngine.index,
      });
      return granted;
    } on PlatformException catch (e) {
      throw EasySpeechToTextException(
          'Failed to request permissions: ${e.message}',
          code: e.code);
    }
  }

  @override
  Future<void> startListening({
    String? localeId,
    List<String>? customWords,
    bool partialResults = true,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      throw EasySpeechToTextException(
          'EasySpeechToText has not been initialized. Call initialize() first.');
    }

    if (customWords != null &&
        customWords.isNotEmpty &&
        _currentEngine == SpeechEngine.native &&
        Platform.isAndroid) {
      throw EasySpeechToTextException(
          'Custom words are not supported on Android native API.');
    }

    _customWords = customWords ?? [];

    // Invoke native method to start recognition.
    try {
      await _methodChannel.invokeMethod('startListening', {
        'engine': _currentEngine.index,
        'localeId': localeId,
        'partialResults': partialResults,
        'pauseFor': pauseFor?.inMilliseconds,
        'customWords': _customWords,
      });
    } on PlatformException catch (e) {
      throw EasySpeechToTextException('Failed to start listening: ${e.message}',
          code: e.code);
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _methodChannel.invokeMethod('stopListening', {
        'engine': _currentEngine.index,
      });
    } on PlatformException catch (e) {
      throw EasySpeechToTextException('Failed to stop listening: ${e.message}',
          code: e.code);
    }
  }

  @override
  Future<void> cancelListening() async {
    try {
      await _methodChannel.invokeMethod('cancelListening', {
        'engine': _currentEngine.index,
      });
    } on PlatformException catch (e) {
      throw EasySpeechToTextException(
          'Failed to cancel listening: ${e.message}',
          code: e.code);
    }
  }

  @override
  Future<String?> transcribe({
    required String filePath,
    String? localeId,
    List<String>? customWords,
  }) async {
    if (!_isInitialized) {
      throw EasySpeechToTextException(
          'EasySpeechToText has not been initialized. Call initialize() first.');
    }

    try {
      final String? result = await _methodChannel.invokeMethod('transcribe', {
        'engine': _currentEngine.index,
        'filePath': filePath,
        'localeId': localeId,
        'customWords': customWords,
      });
      return result;
    } on PlatformException catch (e) {
      throw EasySpeechToTextException(
          'Failed to transcribe audio file: ${e.message}',
          code: e.code);
    }
  }

  @override
  void setCustomWords(List<String> words) {
    _customWords = words;
  }

  @override
  Future<List<LocaleName>> getAvailableLanguages() async {
    try {
      final List<dynamic> locales =
          await _methodChannel.invokeMethod('getAvailableLanguages', {
        'engine': _currentEngine.index,
      });
      return locales.map((locale) {
        final Map<String, dynamic> localeMap =
            Map<String, dynamic>.from(locale);
        return LocaleName(localeMap['localeId'], localeMap['name']);
      }).toList();
    } on PlatformException catch (e) {
      throw EasySpeechToTextException(
          'Failed to get available languages: ${e.message}',
          code: e.code);
    }
  }
}
