import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'easy_speech_to_text_method_channel.dart';

abstract class EasySpeechToTextPlatform extends PlatformInterface {
  /// Constructs a EasySpeechToTextPlatform.
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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
