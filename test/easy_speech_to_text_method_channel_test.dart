import 'package:easy_speech_to_text/speech_engine.dart';
import 'package:easy_speech_to_text/src/easy_speech_to_text_exceptions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_speech_to_text/src/easy_speech_to_text_method_channel.dart';
import 'package:easy_speech_to_text/easy_speech_to_text.dart';

void main() {
  // TestWidgetsFlutterBinding ensures that Flutter's asynchronous nature is correctly handled in tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelEasySpeechToText', () {
    // Mocking the MethodChannel for testing platform-specific method calls
    const MethodChannel channel = MethodChannel('easy_speech_to_text/methods');
    final MethodChannelEasySpeechToText platform =
        MethodChannelEasySpeechToText();

    setUp(() {
      // Mocking platform channel handlers before each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'initialize') {
          return null;
        } else if (methodCall.method == 'hasPermission') {
          return true;
        } else if (methodCall.method == 'transcribe') {
          return 'transcribed text';
        }
        // Default case for unimplemented methods
        throw PlatformException(
            code: 'METHOD_NOT_IMPLEMENTED', message: 'Method not implemented');
      });
    });

    tearDown(() {
      // Reset the mock method handler after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    // Test if 'initialize' method is correctly invoked
    test('initialize should call platform method', () async {
      await platform.initialize(engine: SpeechEngine.native);
    });

    // Test if 'hasPermission' method returns true as expected
    test('hasPermission should return true', () async {
      final result = await platform.hasPermission();
      expect(result, isTrue);
    });

    // Test if 'transcribe' method returns the correct transcribed text
    test('transcribe should return correct text', () async {
      final result = await platform.transcribe(filePath: 'path/to/file.wav');
      expect(result, equals('transcribed text'));
    });

    // Test if calling an unimplemented method throws the correct exception
    test('should throw EasySpeechToTextException for unimplemented methods',
        () async {
      expect(
          () async => await platform.stopListening(),
          throwsA(predicate((e) =>
              e is EasySpeechToTextException &&
              e.code == 'METHOD_NOT_IMPLEMENTED')));
    });

    // Test if 'transcribe' throws exception for invalid file path
    test('transcribe should throw exception on invalid file path', () async {
      // Mocking 'transcribe' method to throw a PlatformException for invalid file
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'transcribe') {
          throw PlatformException(
              code: 'INVALID_FILE', message: 'Invalid file path');
        }
        return null;
      });

      // Expecting EasySpeechToTextException when an invalid file is provided
      expect(
        () async => await platform.transcribe(filePath: 'invalid/path'),
        throwsA(predicate(
            (e) => e is EasySpeechToTextException && e.code == 'INVALID_FILE')),
      );
    });

    // Test if 'startListening' can handle valid localeId and custom words
    test('startListening should call platform with valid params', () async {
      // Mocking startListening for successful case
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startListening') {
          return null;
        }
        return null;
      });

      await platform.startListening(
        localeId: 'en_US',
        customWords: ['flutter', 'dart'],
        partialResults: true,
        pauseFor: const Duration(seconds: 2),
      );
    });

    // Test if 'startListening' throws exception for unsupported custom words on Android
    test(
        'startListening should throw exception for unsupported custom words on Android',
        () async {
      // Mocking startListening to simulate exception on Android
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'startListening') {
          throw PlatformException(
              code: 'UNSUPPORTED_FEATURE',
              message: 'Custom words not supported on Android');
        }
        return null;
      });

      // Expecting EasySpeechToTextException when trying to use custom words on Android native
      expect(
        () async => await platform.startListening(
          localeId: 'en_US',
          customWords: ['flutter', 'dart'],
          partialResults: true,
          pauseFor: const Duration(seconds: 2),
        ),
        throwsA(predicate((e) =>
            e is EasySpeechToTextException && e.code == 'UNSUPPORTED_FEATURE')),
      );
    });

    // Test if 'stopListening' works as expected
    test('stopListening should call platform method', () async {
      // Mocking stopListening for successful case
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'stopListening') {
          return null;
        }
        return null;
      });

      await platform.stopListening();
    });

    // Test if 'cancelListening' works as expected
    test('cancelListening should call platform method', () async {
      // Mocking cancelListening for successful case
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'cancelListening') {
          return null;
        }
        return null;
      });

      await platform.cancelListening();
    });
  });
}
