import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_speech_to_text/easy_speech_to_text.dart';
import 'package:easy_speech_to_text/src/easy_speech_to_text_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A mock implementation of EasySpeechToTextPlatform for unit testing.
/// It overrides all methods from the platform interface and uses a
/// StreamController to simulate the streaming of speech recognition results.
class MockEasySpeechToTextPlatform extends EasySpeechToTextPlatform
    with MockPlatformInterfaceMixin {
  /// Tracks if the initialize method has been called.
  bool initializeCalled = false;

  /// Stream controller to simulate real-time events (like speech results).
  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>();

  /// Simulates the initialization process of the speech recognition platform.
  @override
  Future<void> initialize(
      {required SpeechEngine engine, Map<String, dynamic>? options}) async {
    initializeCalled = true;
  }

  /// Simulates checking for microphone permission and always returns `true`.
  @override
  Future<bool> hasPermission() async {
    return true;
  }

  /// Simulates requesting microphone permission and always returns `true`.
  @override
  Future<bool> requestPermission() async {
    return true;
  }

  /// Simulates starting speech recognition. After a 100 ms delay, it sends a
  /// mock result to the stream to simulate receiving a speech recognition result.
  @override
  Future<void> startListening({
    String? localeId,
    List<String>? customWords,
    bool partialResults = true,
    Duration? pauseFor,
  }) async {
    Future.delayed(const Duration(milliseconds: 100), () {
      _eventStreamController.add({'result': 'mock result'});
    });
  }

  /// Simulates stopping the speech recognition.
  @override
  Future<void> stopListening() async {}

  /// Simulates canceling the speech recognition process.
  @override
  Future<void> cancelListening() async {}

  /// Simulates transcribing an audio file and returns a mock transcription result.
  @override
  Future<String?> transcribe({
    required String filePath,
    String? localeId,
    List<String>? customWords,
  }) async {
    return "transcribed text";
  }

  /// Simulates retrieving a list of available languages for speech recognition.
  /// Returns English (United States) and Chinese (Taiwan) as mock options.
  @override
  Future<List<LocaleName>> getAvailableLanguages() async {
    return [
      LocaleName('en_US', 'English (United States)'),
      LocaleName('zh_TW', 'Chinese (Taiwan)'),
    ];
  }

  /// Provides a stream of mock speech recognition results.
  @override
  Stream<dynamic> get onSpeechResult => _eventStreamController.stream;

  /// Cleans up resources by closing the StreamController.
  void dispose() {
    _eventStreamController.close();
  }
}

void main() {
  late EasySpeechToText easySpeechToText;
  late MockEasySpeechToTextPlatform mockPlatform;

  /// Sets up the mock platform before each test, ensuring that EasySpeechToText
  /// uses the mocked platform instance for testing.
  setUp(() {
    mockPlatform = MockEasySpeechToTextPlatform();
    EasySpeechToTextPlatform.instance = mockPlatform;
    easySpeechToText = EasySpeechToText();
  });

  /// Cleans up resources after each test by disposing the mock platform.
  tearDown(() {
    mockPlatform.dispose();
  });

  group('EasySpeechToText', () {
    /// Tests that the initialize method calls the platform's initialize method.
    test('initialize should call platform initialize', () async {
      await easySpeechToText.initialize();
      expect(mockPlatform.initializeCalled, isTrue);
    });

    /// Tests that hasPermission returns the correct result from the platform.
    test('hasPermission should return platform result', () async {
      final result = await easySpeechToText.hasPermission();
      expect(result, isTrue);
    });

    /// Tests that requestPermission returns the correct result from the platform.
    test('requestPermission should return platform result', () async {
      final result = await easySpeechToText.requestPermission();
      expect(result, isTrue);
    });

    /// Tests that startListening calls the platform's startListening and ensures
    /// that the speech result is received correctly.
    test(
        'startListening should call platform startListening and receive result',
        () async {
      String? recognizedText;

      await easySpeechToText.startListening(
        localeId: 'en_US',
        customWords: ['flutter', 'dart'],
        onResult: (text) {
          recognizedText = text;
        },
      );

      await Future.delayed(
          const Duration(milliseconds: 150)); // Simulates delay for event

      // Verifies that the result from the mock platform is received correctly.
      expect(recognizedText, equals('mock result'));
    });

    /// Tests that stopListening calls the platform's stopListening method without
    /// throwing any exceptions.
    test('stopListening should call platform stopListening', () async {
      await easySpeechToText.stopListening();
      // No exception indicates the method was called correctly.
    });

    /// Tests that cancelListening calls the platform's cancelListening method without
    /// throwing any exceptions.
    test('cancelListening should call platform cancelListening', () async {
      await easySpeechToText.cancelListening();
      // No exception indicates the method was called correctly.
    });

    /// Tests that transcribe returns the correct transcription from the platform.
    test('transcribe should return transcription from platform', () async {
      final result =
          await easySpeechToText.transcribe(filePath: 'path/to/file.wav');
      expect(result, equals('transcribed text'));
    });

    /// Tests that getAvailableLanguages returns the correct list of languages from
    /// the platform.
    test('getAvailableLanguages should return list from platform', () async {
      final languages = await easySpeechToText.getAvailableLanguages();
      expect(languages, hasLength(2));
      expect(languages.first.localeId, equals('en_US'));
      expect(languages.first.name, equals('English (United States)'));
    });
  });
}
