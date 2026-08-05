import 'package:realm_idle_game/features/content/models/alchemy.dart';

class ActiveBuff {
  final String sourcePotionId;
  final BuffType type;
  final double potency;
  final int startedAtEpochMilliseconds;
  final int expiresAtEpochMilliseconds;

  const ActiveBuff({
    required this.sourcePotionId,
    required this.type,
    required this.potency,
    required this.startedAtEpochMilliseconds,
    required this.expiresAtEpochMilliseconds,
  });

  double get multiplier => 1 + potency;

  bool isActiveAt(DateTime now) =>
      expiresAtEpochMilliseconds > now.millisecondsSinceEpoch;

  Duration remainingAt(DateTime now) {
    final remaining = expiresAtEpochMilliseconds - now.millisecondsSinceEpoch;
    return Duration(milliseconds: remaining.clamp(0, 864000000));
  }

  Map<String, dynamic> toJson() => {
    'sourcePotionId': sourcePotionId,
    'type': type.saveKey,
    'potency': potency,
    'startedAtEpochMilliseconds': startedAtEpochMilliseconds,
    'expiresAtEpochMilliseconds': expiresAtEpochMilliseconds,
  };

  factory ActiveBuff.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Invalid active buff');
    final sourcePotionId = json['sourcePotionId'];
    final typeKey = json['type'];
    final potency = json['potency'];
    final startedAt = json['startedAtEpochMilliseconds'];
    final expiresAt = json['expiresAtEpochMilliseconds'];
    final type = typeKey is String
        ? BuffTypeDetails.fromSaveKey(typeKey)
        : null;
    if (sourcePotionId is! String ||
        sourcePotionId.isEmpty ||
        type == null ||
        potency is! num ||
        !potency.isFinite ||
        potency <= 0 ||
        startedAt is! num ||
        !startedAt.isFinite ||
        expiresAt is! num ||
        !expiresAt.isFinite ||
        expiresAt <= startedAt) {
      throw const FormatException('Incomplete active buff');
    }
    return ActiveBuff(
      sourcePotionId: sourcePotionId,
      type: type,
      potency: potency.toDouble().clamp(0.001, 10),
      startedAtEpochMilliseconds: startedAt.toInt().clamp(0, 8640000000000000),
      expiresAtEpochMilliseconds: expiresAt.toInt().clamp(1, 8640000000000000),
    );
  }
}

class ActiveBuffs {
  final Map<BuffType, ActiveBuff> activeByType;

  ActiveBuffs({Map<BuffType, ActiveBuff>? activeByType})
    : activeByType = activeByType ?? {};

  ActiveBuff activate(PotionDefinition potion, DateTime now) {
    final startedAt = now.millisecondsSinceEpoch;
    final buff = ActiveBuff(
      sourcePotionId: potion.id,
      type: potion.buffType,
      potency: potion.potency,
      startedAtEpochMilliseconds: startedAt,
      expiresAtEpochMilliseconds:
          startedAt + (potion.durationSeconds * Duration.millisecondsPerSecond),
    );
    activeByType[potion.buffType] = buff;
    return buff;
  }

  ActiveBuff? activeFor(BuffType type, DateTime now) {
    final buff = activeByType[type];
    return buff != null && buff.isActiveAt(now) ? buff : null;
  }

  double multiplierFor(BuffType type, DateTime now) {
    return activeFor(type, now)?.multiplier ?? 1;
  }

  int pruneExpired(DateTime now) {
    final expired = activeByType.entries
        .where((entry) => !entry.value.isActiveAt(now))
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final type in expired) {
      activeByType.remove(type);
    }
    return expired.length;
  }

  Map<String, dynamic> toJson() => {
    for (final entry in activeByType.entries)
      entry.key.saveKey: entry.value.toJson(),
  };

  factory ActiveBuffs.fromJson(Object? json) {
    if (json is! Map) return ActiveBuffs();
    final buffs = <BuffType, ActiveBuff>{};
    for (final entry in json.entries) {
      if (entry.key is! String) continue;
      try {
        final buff = ActiveBuff.fromJson(entry.value);
        buffs[buff.type] = buff;
      } on FormatException {
        // Saves parciais ou antigos não devem impedir o carregamento do jogo.
      }
    }
    return ActiveBuffs(activeByType: buffs);
  }
}
