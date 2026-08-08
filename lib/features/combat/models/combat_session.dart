import 'package:realm_idle_game/core/utils/offline_progress_policy.dart';

class CombatSession {
  final String encounterId;
  final int cycleDurationMilliseconds;
  int timeRemainingMilliseconds;
  int lastProcessedAt;
  String? queuedEncounterId;

  CombatSession({
    required this.encounterId,
    required this.cycleDurationMilliseconds,
    required this.timeRemainingMilliseconds,
    required this.lastProcessedAt,
    this.queuedEncounterId,
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
    return elapsedMilliseconds.clamp(
      0,
      OfflineProgressPolicy.maxElapsedMilliseconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'encounterId': encounterId,
    'cycleDurationMilliseconds': cycleDurationMilliseconds,
    'timeRemainingMilliseconds': timeRemainingMilliseconds,
    'lastProcessedAt': lastProcessedAt,
    'queuedEncounterId': queuedEncounterId,
  };

  factory CombatSession.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Invalid combat session');
    }

    final encounterId = json['encounterId'];
    final cycleDurationMilliseconds = _millisecondsValue(
      json['cycleDurationMilliseconds'],
      legacySeconds: json['cycleDurationSeconds'],
    );
    final timeRemainingMilliseconds = _millisecondsValue(
      json['timeRemainingMilliseconds'],
      legacySeconds: json['timeRemainingSeconds'],
    );
    final lastProcessedAt = json['lastProcessedAt'];
    if (encounterId is! String ||
        cycleDurationMilliseconds == null ||
        timeRemainingMilliseconds == null ||
        lastProcessedAt is! num ||
        !lastProcessedAt.isFinite) {
      throw const FormatException('Incomplete combat session');
    }

    final cycleDuration = cycleDurationMilliseconds.clamp(1, 86400000);
    final timeRemaining = timeRemainingMilliseconds.clamp(1, cycleDuration);
    return CombatSession(
      encounterId: encounterId,
      cycleDurationMilliseconds: cycleDuration,
      timeRemainingMilliseconds: timeRemaining,
      lastProcessedAt: lastProcessedAt.toInt().clamp(0, 8640000000000000),
      queuedEncounterId: json['queuedEncounterId'] is String
          ? json['queuedEncounterId'] as String
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
