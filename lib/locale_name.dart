/// Represents a language option.
class LocaleName {
  /// Language code, e.g., "en_US".
  final String localeId;

  /// Language name, e.g., "English (United States)".
  final String name;

  /// Creates a new [LocaleName] instance.
  LocaleName(this.localeId, this.name);
}
