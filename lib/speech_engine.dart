/// Types of speech recognition engines.
enum SpeechEngine {
  /// Use the device's native speech recognition capabilities.
  native,

  /// Use Google Cloud Speech-to-Text.
  google,

  /// Use Azure Cognitive Services.
  azure,
}
