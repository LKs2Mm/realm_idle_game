class NotificationSettings {
  bool enabled;

  NotificationSettings({this.enabled = false});

  Map<String, dynamic> toJson() => {'enabled': enabled};

  factory NotificationSettings.fromJson(Object? json) {
    if (json is! Map) return NotificationSettings();
    final enabled = json['enabled'];
    return NotificationSettings(enabled: enabled is bool ? enabled : false);
  }
}
