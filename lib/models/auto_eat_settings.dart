class AutoEatSettings {
  static const int defaultThresholdPercent = 50;
  static const int minThresholdPercent = 10;
  static const int maxThresholdPercent = 90;

  bool enabled;
  int thresholdPercent;

  AutoEatSettings({
    this.enabled = false,
    this.thresholdPercent = defaultThresholdPercent,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'thresholdPercent': thresholdPercent,
  };

  factory AutoEatSettings.fromJson(Object? json) {
    if (json is! Map) return AutoEatSettings();
    final enabled = json['enabled'];
    final thresholdPercent = json['thresholdPercent'];
    return AutoEatSettings(
      enabled: enabled is bool ? enabled : false,
      thresholdPercent: thresholdPercent is int
          ? thresholdPercent.clamp(minThresholdPercent, maxThresholdPercent)
          : defaultThresholdPercent,
    );
  }
}
