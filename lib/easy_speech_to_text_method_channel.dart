import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'easy_speech_to_text_platform_interface.dart';

/// An implementation of [EasySpeechToTextPlatform] that uses method channels.
class MethodChannelEasySpeechToText extends EasySpeechToTextPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('easy_speech_to_text');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
