import 'package:flutter/material.dart';

abstract final class MedievalAssets {
  static const String background =
      'assets/images/medieval/dark-stone-background.png';
  static const String crest = 'assets/images/medieval/realm-crest.png';
  static const String mining = 'assets/images/medieval/mining-emblem.png';
  static const String woodcutting =
      'assets/images/medieval/woodcutting-emblem.png';
  static const String fishing = 'assets/images/medieval/fishing-emblem.png';
  static const String runicDivider = 'assets/images/medieval/runic-divider.png';
  static const String classArmory = 'assets/images/medieval/class-armory.png';
  static const String workshopHall = 'assets/images/medieval/workshop-hall.png';
  static const String worldMap = 'assets/images/medieval/world-map.png';
  static const String alchemyLab =
      'assets/images/medieval/gathering/oficinas/alchemy_lab.png';

  static String? forSkill(String skillId) => switch (skillId) {
    'mining' => mining,
    'woodcutting' => woodcutting,
    'fishing' => fishing,
    _ => null,
  };

  static String gatheringItemAsset(String itemFolder, String itemId) =>
      'assets/images/medieval/gathering/$itemFolder/$itemId.png';

  static String toolAsset(String toolId) =>
      'assets/images/medieval/gathering/ferramentas/${toolId.replaceAll(':', '_')}.png';

  static String enemyAsset(String encounterId) =>
      'assets/images/medieval/gathering/criaturas/$encounterId.png';

  static String classAsset(String heroClassSaveKey) =>
      'assets/images/medieval/gathering/classes/$heroClassSaveKey.png';

  static String workshopAsset(String workshopSaveKey) =>
      'assets/images/medieval/gathering/oficinas/$workshopSaveKey.png';

  /// Uma das 24 ilustrações-base (classe × slot) que cobrem as 2.400
  /// variações de equipamento; a cor do material é aplicada por cima via
  /// `MedievalEmblem.tintColor`, não por arte própria. Ver Lote 4 em
  /// `Realm Idle - Planejamento/11 - Guia de Estilo e Prompts de Arte.md`.
  static String equipmentAsset(String heroClassSaveKey, String slotSaveKey) =>
      'assets/images/medieval/gathering/equipamentos/${heroClassSaveKey}_$slotSaveKey.png';

  static String potionAsset(String potionId) =>
      'assets/images/medieval/gathering/pocoes/$potionId.png';

  static String spellAsset(String spellId) =>
      'assets/images/medieval/gathering/magias/$spellId.png';

  static String combatDropAsset(String dropId) =>
      'assets/images/medieval/gathering/espolios/$dropId.png';
}

class MedievalEmblem extends StatelessWidget {
  final String assetPath;
  final double size;
  final bool muted;
  final Color? tintColor;
  final String? semanticLabel;

  const MedievalEmblem({
    super.key,
    required this.assetPath,
    required this.size,
    this.muted = false,
    this.tintColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.none,
      cacheWidth: (size * 3).round(),
      semanticLabel: semanticLabel,
    );

    final tint = tintColor;
    if (tint != null) {
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
        child: image,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Opacity(
        opacity: muted ? 0.38 : 1,
        child: muted
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF454545),
                  BlendMode.saturation,
                ),
                child: image,
              )
            : image,
      ),
    );
  }
}
