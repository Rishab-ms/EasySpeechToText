import 'package:flutter_test/flutter_test.dart';
import 'package:easy_speech_to_text/easy_speech_to_text.dart';
import 'package:easy_speech_to_text/easy_speech_to_text_platform_interface.dart';
import 'package:easy_speech_to_text/easy_speech_to_text_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEasySpeechToTextPlatform
    with MockPlatformInterfaceMixin
    implements EasySpeechToTextPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EasySpeechToTextPlatform initialPlatform = EasySpeechToTextPlatform.instance;

  test('$MethodChannelEasySpeechToText is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEasySpeechToText>());
  });

  test('getPlatformVersion', () async {
    EasySpeechToText easySpeechToTextPlugin = EasySpeechToText();
    MockEasySpeechToTextPlatform fakePlatform = MockEasySpeechToTextPlatform();
    EasySpeechToTextPlatform.instance = fakePlatform;

    expect(await easySpeechToTextPlugin.getPlatformVersion(), '42');
  });
}
