class GatheringSession {
  final String resourceId;
  final int cycleDurationMilliseconds;
  int timeRemainingMilliseconds;
  int lastProcessedAt;
  final String? toolId;
  final double yieldMultiplier;
  String? queuedResourceId;

  GatheringSession({
    required this.resourceId,
    required this.cycleDurationMilliseconds,
    required this.timeRemainingMilliseconds,
    required this.lastProcessedAt,
    this.toolId,
    this.yieldMultiplier = 1.0,
    this.queuedResourceId,
  });

  double get progress {
    if (cycleDurationMilliseconds <= 0) return 0;
    return (1 - (timeRemainingMilliseconds / cycleDurationMilliseconds)).clamp(
      0.0,
      1.0,
    );
  }

  int elapsedMillisecondsAt(DateTime now) {
    final elapsedMilliseconds = now.millisecondsSinceEpoch - lastProcessedAt;
    if (elapsedMilliseconds <= 0) return 0;
    return elapsedMilliseconds;
  }

  Map<String, dynamic> toJson() => {
    'resourceId': resourceId,
    'cycleDurationMilliseconds': cycleDurationMilliseconds,
    'timeRemainingMilliseconds': timeRemainingMilliseconds,
    'lastProcessedAt': lastProcessedAt,
    'toolId': toolId,
    'yieldMultiplier': yieldMultiplier,
    'queuedResourceId': queuedResourceId,
  };

  factory GatheringSession.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Invalid gathering session');
    }

    final resourceId = json['resourceId'];
    final cycleDurationMilliseconds = _millisecondsValue(
      json['cycleDurationMilliseconds'],
      legacySeconds: json['cycleDurationSeconds'],
    );
    final timeRemainingMilliseconds = _millisecondsValue(
      json['timeRemainingMilliseconds'],
      legacySeconds: json['timeRemainingSeconds'],
    );
    final lastProcessedAt = json['lastProcessedAt'];
    if (resourceId is! String ||
        cycleDurationMilliseconds == null ||
        timeRemainingMilliseconds == null ||
        lastProcessedAt is! num) {
      throw const FormatException('Incomplete gathering session');
    }

    final cycleDuration = cycleDurationMilliseconds.clamp(1, 86400000);
    final timeRemaining = timeRemainingMilliseconds.clamp(1, cycleDuration);
    final rawYieldMultiplier = json['yieldMultiplier'];
    final yieldMultiplier =
        rawYieldMultiplier is num &&
            rawYieldMultiplier.isFinite &&
            rawYieldMultiplier >= 1
        ? rawYieldMultiplier.toDouble().clamp(1.0, 100.0)
        : 1.0;

    return GatheringSession(
      resourceId: resourceId,
      cycleDurationMilliseconds: cycleDuration,
      timeRemainingMilliseconds: timeRemaining,
      lastProcessedAt: lastProcessedAt.toInt(),
      toolId: json['toolId'] is String ? json['toolId'] as String : null,
      yieldMultiplier: yieldMultiplier,
      queuedResourceId: json['queuedResourceId'] is String
          ? json['queuedResourceId'] as String
          : null,
    );
  }

  static int? _millisecondsValue(Object? value, {Object? legacySeconds}) {
    if (value is num && value.isFinite) return value.toInt();
    if (legacySeconds is num && legacySeconds.isFinite) {
      return legacySeconds.toInt() * 1000;
    }
    return null;
  }
}
