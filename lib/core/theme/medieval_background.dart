import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';

class MedievalBackground extends StatelessWidget {
  final Widget child;

  const MedievalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppTheme.darkBackground),
        Image.asset(
          MedievalAssets.background,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          cacheWidth: 768,
          opacity: const AlwaysStoppedAnimation(0.46),
          excludeFromSemantics: true,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.05,
              colors: [Color(0x16000000), Color(0xC9000000)],
              stops: [0.28, 1],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x4A000000), Color(0x12000000), Color(0x8A000000)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
