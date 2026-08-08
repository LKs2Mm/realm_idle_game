import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/medieval_background.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';

class _OnboardingStep {
  final String assetPath;
  final String title;
  final String body;

  const _OnboardingStep({
    required this.assetPath,
    required this.title,
    required this.body,
  });
}

const List<_OnboardingStep> _onboardingSteps = [
  _OnboardingStep(
    assetPath: MedievalAssets.crest,
    title: 'Bem-vindo(a) a Realm Idle',
    body:
        'Um reino sombrio espera por suas mãos. Cada clique, cada golpe e '
        'cada criação molda a lenda do seu herói — mesmo enquanto você '
        'está longe.',
  ),
  _OnboardingStep(
    assetPath: MedievalAssets.mining,
    title: 'Colheita',
    body:
        'Minere, corte madeira e pesque para reunir os materiais que '
        'sustentam sua jornada. Comece pelos cards da aba Habilidades.',
  ),
  _OnboardingStep(
    assetPath: MedievalAssets.classArmory,
    title: 'Combate',
    body:
        'Enfrente criaturas amaldiçoadas, ganhe ouro e despojos, e evolua '
        'suas quatro classes de combate.',
  ),
  _OnboardingStep(
    assetPath: MedievalAssets.workshopHall,
    title: 'Itens',
    body:
        'Forje equipamentos, prepare poções e inscreva magias nas oficinas '
        'do reino. Tudo que você coleta e conquista vira poder aqui.',
  ),
];

/// Tutorial curto de primeira sessão — 4 balões de texto sem coach-marks
/// apontando pra widgets específicos, só uma introdução rápida ao loop do
/// jogo. Cobre toda a tela até ser dispensado (Pular ou completar o
/// último passo).
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingOverlay({super.key, required this.onFinished});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int _stepIndex = 0;

  void _next() {
    if (_stepIndex == _onboardingSteps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() => _stepIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final step = _onboardingSteps[_stepIndex];
    final isLastStep = _stepIndex == _onboardingSteps.length - 1;

    return Material(
      key: const ValueKey<String>('onboarding-overlay'),
      color: Colors.transparent,
      child: MedievalBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    key: const ValueKey<String>('onboarding-skip'),
                    onPressed: widget.onFinished,
                    child: const Text('Pular'),
                  ),
                ),
                const Spacer(),
                RunicFrame(
                  color: AppTheme.accentYellow,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.accentYellow.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.accentYellow.withValues(alpha: 0.5),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        step.assetPath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  step.title,
                  key: const ValueKey<String>('onboarding-title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.accentYellow,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  step.body,
                  key: const ValueKey<String>('onboarding-body'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _onboardingSteps.length; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _stepIndex ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _stepIndex
                              ? AppTheme.accentYellow
                              : AppTheme.darkCardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const ValueKey<String>('onboarding-next'),
                    onPressed: _next,
                    child: Text(isLastStep ? 'Começar jornada' : 'Próximo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
