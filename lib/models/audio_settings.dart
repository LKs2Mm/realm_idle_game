class AudioSettings {
  static const double defaultMusicVolume = 0.6;
  static const double defaultSfxVolume = 0.8;

  double musicVolume;
  double sfxVolume;
  bool muted;

  AudioSettings({
    this.musicVolume = defaultMusicVolume,
    this.sfxVolume = defaultSfxVolume,
    this.muted = false,
  });

  Map<String, dynamic> toJson() => {
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
    'muted': muted,
  };

  factory AudioSettings.fromJson(Object? json) {
    if (json is! Map) return AudioSettings();
    final musicVolume = json['musicVolume'];
    final sfxVolume = json['sfxVolume'];
    final muted = json['muted'];
    return AudioSettings(
      musicVolume: musicVolume is num && musicVolume.isFinite
          ? musicVolume.toDouble().clamp(0.0, 1.0)
          : defaultMusicVolume,
      sfxVolume: sfxVolume is num && sfxVolume.isFinite
          ? sfxVolume.toDouble().clamp(0.0, 1.0)
          : defaultSfxVolume,
      muted: muted is bool ? muted : false,
    );
  }
}
