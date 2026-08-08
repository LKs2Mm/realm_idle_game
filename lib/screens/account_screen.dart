import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';

typedef ProfileChangedCallback = void Function(String name, String title);

class AccountChronicleEntry {
  final String id;
  final String title;
  final String description;
  final String dateLabel;

  const AccountChronicleEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.dateLabel,
  });
}

class AccountClassStats {
  final HeroClass heroClass;
  final int level;
  final int victories;
  final int power;

  const AccountClassStats({
    required this.heroClass,
    required this.level,
    required this.victories,
    required this.power,
  });
}

class AccountScreen extends StatefulWidget {
  final String characterName;
  final String characterTitle;
  final String saveId;
  final String createdAtLabel;
  final String lastSavedAtLabel;
  final List<AccountClassStats> classStats;
  final List<AccountChronicleEntry> chronicle;
  final double musicVolume;
  final double sfxVolume;
  final bool audioMuted;
  final ProfileChangedCallback onProfileChanged;
  final VoidCallback onSaveRequested;
  final VoidCallback onIdentityRequested;
  final ValueChanged<double> onMusicVolumeChanged;
  final ValueChanged<double> onSfxVolumeChanged;
  final ValueChanged<bool> onAudioMutedChanged;

  const AccountScreen({
    super.key,
    required this.characterName,
    required this.characterTitle,
    required this.saveId,
    required this.createdAtLabel,
    required this.lastSavedAtLabel,
    required this.classStats,
    required this.chronicle,
    required this.musicVolume,
    required this.sfxVolume,
    required this.audioMuted,
    required this.onProfileChanged,
    required this.onSaveRequested,
    required this.onIdentityRequested,
    required this.onMusicVolumeChanged,
    required this.onSfxVolumeChanged,
    required this.onAudioMutedChanged,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.characterName);
    _titleController = TextEditingController(text: widget.characterTitle);
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterName != widget.characterName &&
        _nameController.text != widget.characterName) {
      _nameController.text = widget.characterName;
    }
    if (oldWidget.characterTitle != widget.characterTitle &&
        _titleController.text != widget.characterTitle) {
      _titleController.text = widget.characterTitle;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submitProfile() {
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    widget.onProfileChanged(
      name.isEmpty ? widget.characterName : name,
      title.isEmpty ? widget.characterTitle : title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsByClass = {
      for (final stats in widget.classStats) stats.heroClass: stats,
    };

    return SingleChildScrollView(
      key: const PageStorageKey<String>('account-screen-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AccountHeader(),
          const SizedBox(height: 8),
          const RunicDivider(height: 24, maxWidth: 220),
          const SizedBox(height: 14),
          _ProfileCard(
            nameController: _nameController,
            titleController: _titleController,
            onSubmit: _submitProfile,
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.shield_outlined,
            title: 'CAMINHOS DE BATALHA',
            detail: 'Nenhuma classe é permanente',
          ),
          const SizedBox(height: 9),
          for (final heroClass in HeroClass.values) ...[
            _ClassStatsCard(
              stats:
                  statsByClass[heroClass] ??
                  AccountClassStats(
                    heroClass: heroClass,
                    level: 1,
                    victories: 0,
                    power: 0,
                  ),
            ),
            if (heroClass != HeroClass.values.last) const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.auto_stories_outlined,
            title: 'CRÔNICA',
            detail: 'Marcos desta jornada',
          ),
          const SizedBox(height: 9),
          _Chronicle(entries: widget.chronicle),
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.volume_up_outlined,
            title: 'ÁUDIO',
            detail: 'Trilha e efeitos',
          ),
          const SizedBox(height: 9),
          _AudioSettingsCard(
            musicVolume: widget.musicVolume,
            sfxVolume: widget.sfxVolume,
            muted: widget.audioMuted,
            onMusicVolumeChanged: widget.onMusicVolumeChanged,
            onSfxVolumeChanged: widget.onSfxVolumeChanged,
            onMutedChanged: widget.onAudioMutedChanged,
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.save_outlined,
            title: 'SAVE E IDENTIDADE',
            detail: 'Dados deste reino',
          ),
          const SizedBox(height: 9),
          _SaveIdentityCard(
            saveId: widget.saveId,
            createdAtLabel: widget.createdAtLabel,
            lastSavedAtLabel: widget.lastSavedAtLabel,
            onSave: widget.onSaveRequested,
            onIdentity: widget.onIdentityRequested,
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _IconSeal(icon: Icons.person_outline, size: 46),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conta',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentYellow,
                  fontSize: 24,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Sua identidade, feitos e caminhos pelo reino.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController titleController;
  final VoidCallback onSubmit;

  const _ProfileCard({
    required this.nameController,
    required this.titleController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: RunicFrame(
        color: AppTheme.accentYellow,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'IDENTIDADE DO HERÓI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentYellow,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('account-name-field'),
                controller: nameController,
                maxLength: 24,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  counterText: '',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('account-title-field'),
                controller: titleController,
                maxLength: 32,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  labelText: 'Título',
                  counterText: '',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 11),
              ElevatedButton.icon(
                key: const ValueKey<String>('account-save-profile'),
                onPressed: onSubmit,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Atualizar identidade'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassStatsCard extends StatelessWidget {
  final AccountClassStats stats;

  const _ClassStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = _classColor(stats.heroClass);
    return Card(
      key: ValueKey<String>('account-class-${stats.heroClass.saveKey}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: MedievalEmblem(
                assetPath: MedievalAssets.classAsset(stats.heroClass.saveKey),
                size: 42,
                semanticLabel: stats.heroClass.displayName,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.heroClass.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      _Metric(label: 'Nível', value: '${stats.level}'),
                      _Metric(label: 'Vitórias', value: '${stats.victories}'),
                      _Metric(label: 'Poder', value: '${stats.power}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
    );
  }
}

class _Chronicle extends StatelessWidget {
  final List<AccountChronicleEntry> entries;

  const _Chronicle({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyPanel(
        icon: Icons.history_toggle_off,
        message: 'A crônica ainda aguarda seu primeiro grande feito.',
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              _ChronicleRow(entry: entries[index]),
              if (index < entries.length - 1)
                const Divider(height: 20, color: AppTheme.darkCardBorder),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChronicleRow extends StatelessWidget {
  final AccountChronicleEntry entry;

  const _ChronicleRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey<String>('chronicle-${entry.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: RunicGlyph(size: 10),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.dateLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                entry.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaveIdentityCard extends StatelessWidget {
  final String saveId;
  final String createdAtLabel;
  final String lastSavedAtLabel;
  final VoidCallback onSave;
  final VoidCallback onIdentity;

  const _SaveIdentityCard({
    required this.saveId,
    required this.createdAtLabel,
    required this.lastSavedAtLabel,
    required this.onSave,
    required this.onIdentity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: AppTheme.combatBlue,
        opacity: 0.45,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectableText(
                saveId,
                key: const ValueKey<String>('account-save-id'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.combatBlue,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Criado: $createdAtLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Salvo: $lastSavedAtLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    key: const ValueKey<String>('account-save-now'),
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined, size: 17),
                    label: const Text('Salvar agora'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey<String>('account-copy-identity'),
                    onPressed: onIdentity,
                    icon: const Icon(Icons.fingerprint, size: 17),
                    label: const Text('Identidade'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioSettingsCard extends StatelessWidget {
  final double musicVolume;
  final double sfxVolume;
  final bool muted;
  final ValueChanged<double> onMusicVolumeChanged;
  final ValueChanged<double> onSfxVolumeChanged;
  final ValueChanged<bool> onMutedChanged;

  const _AudioSettingsCard({
    required this.musicVolume,
    required this.sfxVolume,
    required this.muted,
    required this.onMusicVolumeChanged,
    required this.onSfxVolumeChanged,
    required this.onMutedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: AppTheme.accentYellow,
        opacity: 0.45,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                key: const ValueKey<String>('account-audio-mute'),
                contentPadding: EdgeInsets.zero,
                value: muted,
                onChanged: onMutedChanged,
                title: const Text('Silenciar tudo'),
                secondary: Icon(
                  muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                  color: AppTheme.accentYellow,
                ),
              ),
              _VolumeSlider(
                sliderKey: const ValueKey<String>('account-audio-music'),
                icon: Icons.music_note_outlined,
                label: 'Música',
                value: musicVolume,
                enabled: !muted,
                onChanged: onMusicVolumeChanged,
              ),
              _VolumeSlider(
                sliderKey: const ValueKey<String>('account-audio-sfx'),
                icon: Icons.graphic_eq_outlined,
                label: 'Efeitos',
                value: sfxVolume,
                enabled: !muted,
                onChanged: onSfxVolumeChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final Key sliderKey;
  final IconData icon;
  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.sliderKey,
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value.clamp(0.0, 1.0) * 100).round();
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Semantics(
            label: label,
            value: '$percent%',
            child: Slider(
              key: sliderKey,
              value: value.clamp(0.0, 1.0),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$percent%',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.accentYellow),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.accentYellow,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppTheme.darkCardBorder)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _IconSeal extends StatelessWidget {
  final IconData icon;
  final double size;

  const _IconSeal({required this.icon, this.size = 40});

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.accentYellow;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPanel({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _classColor(HeroClass heroClass) => switch (heroClass) {
  HeroClass.knight => AppTheme.combatRed,
  HeroClass.assassin => const Color(0xFF9D789C),
  HeroClass.mage => AppTheme.combatBlue,
  HeroClass.archer => AppTheme.miningGreenLight,
};
