class IsarService {
  static dynamic get instance =>
      throw UnsupportedError('Isar not available on web');

  static Future<void> initialize() async {}

  static Future<void> close() async {}
}
