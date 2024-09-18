class EasySpeechToTextException implements Exception {
  final String message;
  final String? code;

  EasySpeechToTextException(this.message, {this.code});

  @override
  String toString() {
    if (code != null) {
      return 'EasySpeechToTextException($code): $message';
    }
    return 'EasySpeechToTextException: $message';
  }
}
