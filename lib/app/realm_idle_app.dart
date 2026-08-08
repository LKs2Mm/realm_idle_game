import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:realm_idle_game/core/audio/audio_assets.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_background.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/features/combat/services/combat_service.dart';
import 'package:realm_idle_game/features/content/data/potion_catalog.dart';
import 'package:realm_idle_game/features/content/data/spell_catalog.dart';
import 'package:realm_idle_game/features/content/data/world_region_catalog.dart';
import 'package:realm_idle_game/features/equipment/data/equipment_catalog.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/gathering/screens/gathering_screen.dart';
import 'package:realm_idle_game/features/gathering/services/gathering_service.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/features/production/services/production_service.dart';
import 'package:realm_idle_game/features/tools/screens/tools_screen.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/screens/account_screen.dart';
import 'package:realm_idle_game/screens/combat_screen.dart';
import 'package:realm_idle_game/screens/items_screen.dart';
import 'package:realm_idle_game/screens/maps_screen.dart';
import 'package:realm_idle_game/screens/skills_screen.dart';
import 'package:realm_idle_game/services/audio_service.dart';
import 'package:realm_idle_game/services/storage_service.dart';
import 'package:realm_idle_game/widgets/header_widget.dart';

class RealmIdleApp extends StatelessWidget {
  const RealmIdleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realm Idle',
      theme: AppTheme.theme,
      home: const GameShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameShell extends StatefulWidget {
  const GameShell({super.key});

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> with WidgetsBindingObserver {
  late GameState _gameState;
  late GatheringService _gatheringService;
  late CombatService _combatService;
  late ProductionService _productionService;
  GatheringAdvanceResult? _offlineGatheringReport;
  CombatAdvanceResult? _offlineCombatReport;
  int _selectedIndex = 0;
  GatheringDiscipline _selectedToolDiscipline = GatheringDiscipline.mining;
  GatheringDiscipline _selectedGatheringDiscipline = GatheringDiscipline.mining;
  int _selectedItemsTabIndex = 0;
  DateTime _lastSavedAt = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGameState();
  }

  Future<void> _loadGameState() async {
    final savedState = await StorageService.loadGameState();
    if (!mounted) return;

    final gameState = savedState ?? GameState();
    _gatheringService = GatheringService(onUpdate: _onGatheringUpdate);
    _combatService = CombatService(onUpdate: _onCombatUpdate);
    _productionService = ProductionService(onUpdate: _onProductionUpdate);
    final gatheringReport = _gatheringService.initialize(gameState);
    final combatReport = _combatService.initialize(gameState);
    final productionReport = _productionService.initialize(gameState);

    setState(() {
      _gameState = gameState;
      _offlineGatheringReport = gatheringReport.hasRewards
          ? gatheringReport
          : null;
      _offlineCombatReport = combatReport.hasRewards ? combatReport : null;
      _lastSavedAt = DateTime.now();
      _isLoading = false;
    });
    unawaited(AudioService.initialize(gameState.audioSettings));
    _updateMusicForScreen();
    if (gatheringReport.hasRewards ||
        combatReport.hasRewards ||
        productionReport.hasReward) {
      unawaited(StorageService.saveGameState(gameState));
    }
    if (productionReport.hasReward) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showMessage(
          '${productionReport.reward!.kind.displayName} concluído durante sua ausência.',
        );
      });
    }
  }

  void _onCombatUpdate(GameState gameState, bool shouldSave) {
    if (!mounted) return;
    setState(() => _gameState = gameState);
    if (shouldSave) _saveState();
  }

  void _onGatheringUpdate(GameState gameState, bool shouldSave) {
    if (!mounted) return;
    setState(() => _gameState = gameState);
    if (shouldSave) _saveState();
  }

  void _onProductionUpdate(GameState gameState, bool shouldSave) {
    if (!mounted) return;
    setState(() => _gameState = gameState);
    if (shouldSave) _saveState();
  }

  void _saveState() {
    _lastSavedAt = DateTime.now();
    unawaited(StorageService.saveGameState(_gameState));
  }

  void _updateMusicForScreen() {
    unawaited(
      AudioService.playMusic(
        _selectedIndex == 2
            ? AudioAssets.combatTheme
            : AudioAssets.explorationTheme,
      ),
    );
  }

  void _setMusicVolume(double volume) {
    _gameState.setMusicVolume(volume);
    unawaited(AudioService.applySettings(_gameState.audioSettings));
    setState(() {});
    _saveState();
  }

  void _setSfxVolume(double volume) {
    _gameState.setSfxVolume(volume);
    unawaited(AudioService.applySettings(_gameState.audioSettings));
    setState(() {});
    _saveState();
  }

  void _setAudioMuted(bool muted) {
    _gameState.setAudioMuted(muted);
    unawaited(AudioService.applySettings(_gameState.audioSettings));
    setState(() {});
    _saveState();
  }

  void _dismissOfflineGatheringReport() {
    setState(() => _offlineGatheringReport = null);
  }

  void _dismissOfflineCombatReport() {
    setState(() => _offlineCombatReport = null);
  }

  void _onToolStateChanged() {
    if (!mounted) return;
    setState(() {});
    _saveState();
  }

  void _craftEquipment(String equipmentId) {
    final result = _gameState.craftEquipment(equipmentId);
    _finishProductionStart(result);
  }

  void _craftSpell(String spellId) {
    final result = _gameState.craftSpell(spellId);
    _finishProductionStart(result);
  }

  void _brewPotion(String potionId) {
    final result = _gameState.brewPotion(potionId);
    _finishProductionStart(result);
  }

  void _startProcessing(String recipeId, int quantity) {
    final result = _gameState.startProcessing(recipeId, quantity: quantity);
    _finishProductionStart(result);
  }

  void _eatCookedFish(String foodId) {
    final result = _gameState.consumeCookedFish(foodId);
    switch (result) {
      case FoodUseResult.success:
        setState(() {});
        _saveState();
        _showMessage('A refeição restaurou sua vida.');
      case FoodUseResult.fullHealth:
        _showMessage('Sua vida já está completa.');
      case FoodUseResult.notOwned:
        _showMessage('Você não possui esta refeição.');
      case FoodUseResult.unknownFood:
        _showMessage('Esta refeição não pertence ao grimório culinário.');
    }
  }

  void _finishProductionStart(ProductionStartResult result) {
    if (result == ProductionStartResult.success) {
      _productionService.notifyProductionStarted();
      _showMessage('Produção iniciada. A oficina trabalhará sozinha.');
      return;
    }
    _showMessage(_productionErrorMessage(result));
  }

  void _equipItem(String equipmentId) {
    final result = _gameState.equipItem(equipmentId);
    if (result == EquipmentActionResult.success) {
      setState(() {});
      _saveState();
      _showMessage('Equipamento vinculado ao conjunto da classe.');
    } else {
      _showMessage('Este equipamento ainda não pertence ao seu arsenal.');
    }
  }

  void _usePotion(String potionId) {
    if (!_gameState.consumePotion(potionId)) {
      _showMessage('Poção indisponível.');
      return;
    }
    setState(() {});
    _saveState();
    _showMessage('Elixir consumido; o efeito rúnico está ativo.');
  }

  void _useSpell(String spellId) {
    if (!_gameState.equipSpell(spellId)) {
      _showMessage('Inscreva esta magia antes de vinculá-la.');
      return;
    }
    setState(() {});
    _saveState();
    _showMessage('Magia vinculada ao grimório de combate.');
  }

  void _selectRegion(String regionId) {
    if (!_gameState.selectRegion(regionId)) {
      _showMessage('As runas desta região ainda permanecem seladas.');
      return;
    }
    setState(() {});
    _saveState();
    _showMessage('Destino alterado para ${_gameState.selectedRegionName}.');
  }

  void _updateProfile(String name, String title) {
    _gameState.updateProfile(name: name, title: title);
    setState(() {});
    _saveState();
    _showMessage('Identidade gravada na crônica.');
  }

  Future<void> _saveNow() async {
    _lastSavedAt = DateTime.now();
    await StorageService.saveGameState(_gameState);
    if (!mounted) return;
    setState(() {});
    _showMessage('Progresso salvo neste dispositivo.');
  }

  Future<void> _copyIdentity() async {
    await Clipboard.setData(ClipboardData(text: _gameState.saveIdentity));
    if (mounted) _showMessage('Identidade copiada.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _productionErrorMessage(ProductionStartResult result) {
    return switch (result) {
      ProductionStartResult.success => 'Produção iniciada.',
      ProductionStartResult.unknownRecipe => 'Receita desconhecida.',
      ProductionStartResult.productionBusy =>
        'Uma oficina já está trabalhando. Aguarde ou cancele a encomenda.',
      ProductionStartResult.levelRequired =>
        'A oficina ainda não domina esta receita.',
      ProductionStartResult.insufficientGold =>
        'Ouro insuficiente. Conquiste moedas no Combate.',
      ProductionStartResult.insufficientResources =>
        'Faltam materiais de Colheita ou espólios de Combate.',
      ProductionStartResult.alreadyOwned =>
        'Esta criação já pertence ao seu arsenal.',
      ProductionStartResult.invalidQuantity => 'Quantidade inválida.',
    };
  }

  List<AccountChronicleEntry> _buildChronicle() {
    final profile = _gameState.profile;
    return [
      AccountChronicleEntry(
        id: 'awakening',
        title: 'O Despertar',
        description:
            'Uma runa respondeu ao chamado de ${profile.name} na Encruzilhada das Cinzas.',
        dateLabel: _formatDateTime(
          DateTime.fromMillisecondsSinceEpoch(profile.createdAt),
        ),
      ),
      if (profile.totalGatheringCycles > 0)
        AccountChronicleEntry(
          id: 'gathering',
          title: 'Mãos Marcadas',
          description:
              '${profile.totalGatheringCycles} ciclos de coleta concluídos sob as luas mortas.',
          dateLabel: 'Jornada',
        ),
      if (profile.totalVictories > 0)
        AccountChronicleEntry(
          id: 'victories',
          title: 'Sangue nas Runas',
          description:
              '${profile.totalVictories} vitórias conquistadas entre todas as classes.',
          dateLabel: 'Jornada',
        ),
      if (profile.totalCrafts > 0)
        AccountChronicleEntry(
          id: 'crafts',
          title: 'Obras das Cinco Oficinas',
          description:
              '${profile.totalCrafts} criações concluídas por ferreiros, artesãos e ocultistas.',
          dateLabel: 'Jornada',
        ),
      if (profile.potionsConsumed > 0)
        AccountChronicleEntry(
          id: 'alchemy',
          title: 'Sangue Alquímico',
          description:
              '${profile.potionsConsumed} elixires consumidos e gravados no corpo.',
          dateLabel: 'Jornada',
        ),
      if (_gameState.visitedRegionIds.length > 1)
        AccountChronicleEntry(
          id: 'regions',
          title: 'Cartógrafo do Eclipse',
          description:
              '${_gameState.visitedRegionIds.length} regiões alcançadas no mapa rúnico.',
          dateLabel: 'Jornada',
        ),
    ];
  }

  String _formatDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isLoading) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(AudioService.resumeMusic());
      final now = DateTime.now();
      final gatheringReport = _gatheringService.advanceTo(now);
      final combatReport = _combatService.advanceTo(now);
      final productionReport = _productionService.advanceTo(now);
      if ((gatheringReport.hasRewards ||
              combatReport.hasRewards ||
              productionReport.hasReward) &&
          mounted) {
        setState(() {
          if (gatheringReport.hasRewards) {
            _offlineGatheringReport = gatheringReport;
          }
          if (combatReport.hasRewards) {
            _offlineCombatReport = combatReport;
          }
        });
        if (productionReport.hasReward) {
          _showMessage(
            '${productionReport.reward!.kind.displayName} concluído pela oficina.',
          );
        }
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(AudioService.pauseMusic());
      _saveState();
    }
  }

  Widget _buildItemsScreen({
    required int initialTabIndex,
    HeroClass initialClass = HeroClass.knight,
    VoidCallback? onAfterAction,
  }) {
    void after(void Function() action) {
      action();
      onAfterAction?.call();
    }

    return ItemsScreen(
      gameState: _gameState,
      equipment: _gameState.equipment,
      contentInventory: _gameState.contentInventory,
      equipmentDefinitions: EquipmentCatalog.all,
      potions: PotionCatalog.all,
      spells: SpellCatalog.all,
      workshopLevels: {
        for (final workshop in EquipmentWorkshop.values)
          workshop: _gameState.skills[workshop.skillId]?.level ?? 1,
      },
      availableMaterials: _gameState.gatheringInventory.resources,
      availableGold: _gameState.gold,
      alchemyLevel: _gameState.skills['alchemy']?.level ?? 1,
      magicLevel: _gameState.skills['arcanism']?.level ?? 1,
      activeBuffs: _gameState.activeBuffs,
      activeSpellId: _gameState.activeSpellId,
      activeProductionSession: _gameState.activeProductionSession,
      initialTabIndex: initialTabIndex,
      initialClass: initialClass,
      onCancelProduction: () => after(() {
        _productionService.cancel();
        _showMessage('Encomenda cancelada; os materiais foram devolvidos.');
      }),
      onCraftEquipment: (id) => after(() => _craftEquipment(id)),
      onEquipItem: (id) => after(() => _equipItem(id)),
      onBrewPotion: (id) => after(() => _brewPotion(id)),
      onUsePotion: (id) => after(() => _usePotion(id)),
      onCraftSpell: (id) => after(() => _craftSpell(id)),
      onUseSpell: (id) => after(() => _useSpell(id)),
      onStartProcessing: (id, quantity) =>
          after(() => _startProcessing(id, quantity)),
      onEatFood: (id) => after(() => _eatCookedFish(id)),
    );
  }

  void _openClassEquipmentSheet(HeroClass heroClass) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.94,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Equipar ${heroClass.displayName}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: AppTheme.textSecondary,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildItemsScreen(
                        initialTabIndex: 1,
                        initialClass: heroClass,
                        onAfterAction: () => setModalState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return SkillsScreen(gameState: _gameState, onOpenSkill: _openSkill);
      case 1:
        return GatheringScreen(
          gameState: _gameState,
          service: _gatheringService,
          offlineReport: _offlineGatheringReport,
          onDismissOfflineReport: _dismissOfflineGatheringReport,
          initialDiscipline: _selectedGatheringDiscipline,
          onOpenTools: (discipline) {
            setState(() {
              _selectedToolDiscipline = discipline;
              _selectedIndex = 5;
            });
            _updateMusicForScreen();
          },
        );
      case 2:
        return CombatScreen(
          gameState: _gameState,
          service: _combatService,
          offlineReport: _offlineCombatReport,
          onDismissOfflineReport: _dismissOfflineCombatReport,
          onStateChanged: () {
            setState(() {});
            _saveState();
          },
          onManageEquipment: _openClassEquipmentSheet,
        );
      case 3:
        return _buildItemsScreen(initialTabIndex: _selectedItemsTabIndex);
      case 4:
        return MapsScreen(
          regions: WorldRegionCatalog.all,
          selectedRegionId: _gameState.profile.selectedRegionId,
          combatLevel: _gameState.combatLevel,
          skillLevels: _gameState.skillLevels,
          completedRegionIds: _gameState.visitedRegionIds,
          onSelectRegion: _selectRegion,
        );
      case 5:
        return ToolsScreen(
          gameState: _gameState,
          onStateChanged: _onToolStateChanged,
          initialDiscipline: _selectedToolDiscipline,
        );
      case 6:
        return AccountScreen(
          characterName: _gameState.profile.name,
          characterTitle: _gameState.profile.title,
          saveId: _gameState.saveIdentity,
          createdAtLabel: _formatDateTime(
            DateTime.fromMillisecondsSinceEpoch(_gameState.profile.createdAt),
          ),
          lastSavedAtLabel: _formatDateTime(_lastSavedAt),
          classStats: [
            for (final heroClass in HeroClass.values)
              AccountClassStats(
                heroClass: heroClass,
                level: _gameState.classLevel(heroClass),
                victories: _gameState.victoriesForClass(heroClass),
                power: _gameState.equipmentPowerFor(heroClass),
              ),
          ],
          chronicle: _buildChronicle(),
          musicVolume: _gameState.audioSettings.musicVolume,
          sfxVolume: _gameState.audioSettings.sfxVolume,
          audioMuted: _gameState.audioSettings.muted,
          onProfileChanged: _updateProfile,
          onSaveRequested: _saveNow,
          onIdentityRequested: _copyIdentity,
          onMusicVolumeChanged: _setMusicVolume,
          onSfxVolumeChanged: _setSfxVolume,
          onAudioMutedChanged: _setAudioMuted,
        );
      default:
        return SkillsScreen(gameState: _gameState, onOpenSkill: _openSkill);
    }
  }

  // Colheita (índice 1) só é alcançada pelos cards de Habilidades agora;
  // o menu fixo mostra apenas estes seis destinos.
  static const List<int> _bottomNavScreenIndices = [0, 2, 3, 4, 5, 6];

  static const Map<String, GatheringDiscipline> _gatheringSkillDisciplines = {
    'mining': GatheringDiscipline.mining,
    'woodcutting': GatheringDiscipline.woodcutting,
    'fishing': GatheringDiscipline.fishing,
  };

  static const Map<String, int> _itemsTabIndexBySkill = {
    'smithing': 5, // Processamento (Fundição)
    'crafting': 5, // Processamento (Marcenaria)
    'arcanism': 5, // Processamento (Consagração Arcana)
    'cooking': 5, // Processamento (Culinária)
    'shadowcraft': 2, // Oficinas (Guilda dos Véus)
    'alchemy': 3, // Alquimia
  };

  static const Set<String> _combatSkillIds = {
    'attack',
    'defense',
    'magic',
    'knight_mastery',
    'assassin_mastery',
    'mage_mastery',
    'archer_mastery',
  };

  void _openSkill(String skillId) {
    final discipline = _gatheringSkillDisciplines[skillId];
    if (discipline != null) {
      setState(() {
        _selectedGatheringDiscipline = discipline;
        _selectedIndex = 1;
      });
      _updateMusicForScreen();
      return;
    }

    final itemsTab = _itemsTabIndexBySkill[skillId];
    if (itemsTab != null) {
      setState(() {
        _selectedItemsTabIndex = itemsTab;
        _selectedIndex = 3;
      });
      _updateMusicForScreen();
      return;
    }

    if (_combatSkillIds.contains(skillId)) {
      setState(() => _selectedIndex = 2);
      _updateMusicForScreen();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isLoading) {
      _gatheringService.dispose();
      _combatService.dispose();
      _productionService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: MedievalBackground(
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.progressBar),
            ),
          ),
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final showAllNavigationLabels =
        mediaQuery.size.width >= 390 && mediaQuery.textScaler.scale(1) <= 1.15;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: MedievalBackground(
        child: Column(
          children: [
            HeaderWidget(gameState: _gameState),
            Expanded(child: _buildScreen()),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.darkCardRaised, AppTheme.voidBlack],
          ),
          border: Border(top: BorderSide(color: AppTheme.darkCardBorder)),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavScreenIndices
              .indexOf(_selectedIndex)
              .clamp(0, _bottomNavScreenIndices.length - 1),
          onTap: (visibleIndex) {
            setState(
              () => _selectedIndex = _bottomNavScreenIndices[visibleIndex],
            );
            _updateMusicForScreen();
          },
          selectedFontSize: 9,
          unselectedFontSize: 8,
          showSelectedLabels: true,
          showUnselectedLabels: showAllNavigationLabels,
          iconSize: 22,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              activeIcon: RunicNavIcon(icon: Icons.psychology),
              label: 'Habilidades',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_mma),
              activeIcon: RunicNavIcon(icon: Icons.sports_mma),
              label: 'Combate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.backpack),
              activeIcon: RunicNavIcon(icon: Icons.backpack),
              label: 'Itens',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              activeIcon: RunicNavIcon(icon: Icons.map),
              label: 'Mapas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              activeIcon: RunicNavIcon(icon: Icons.build),
              label: 'Ferramentas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: RunicNavIcon(icon: Icons.person),
              label: 'Conta',
            ),
          ],
        ),
      ),
    );
  }
}
