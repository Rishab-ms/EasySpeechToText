
import 'easy_speech_to_text_platform_interface.dart';

class EasySpeechToText {
  Future<String?> getPlatformVersion() {
    return EasySpeechToTextPlatform.instance.getPlatformVersion();
  }
}
