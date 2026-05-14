/// Pixel statistics
class PixelStats {
  final int totalAppearances;
  final bool isCurrentlyVisible;
  final bool refreshEnabled;
  final int nextRefreshInMs;

  PixelStats._({
    required this.totalAppearances,
    required this.isCurrentlyVisible,
    required this.refreshEnabled,
    required this.nextRefreshInMs,
  });

  factory PixelStats.fromMap(Map<String, dynamic> map) {
    return PixelStats._(
      totalAppearances: map['totalAppearances'] as int,
      isCurrentlyVisible: map['isCurrentlyVisible'] as bool,
      refreshEnabled: map['refreshEnabled'] as bool,
      nextRefreshInMs: map['nextRefreshInMs'] as int,
    );
  }

  /// Get next refresh time in seconds
  int get nextRefreshInSeconds => (nextRefreshInMs / 1000).round();
}
