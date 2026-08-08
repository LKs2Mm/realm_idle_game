/// Política de progresso offline compartilhada por `GatheringSession`,
/// `CombatSession` e `ProductionSession`.
///
/// Limita quanto tempo decorrido é contabilizado de uma vez ao retomar o
/// app, mesmo que o relógio do dispositivo aponte um intervalo maior —
/// sem isso, adiantar o relógio do sistema geraria ciclos de colheita,
/// combate ou produção sem limite.
abstract final class OfflineProgressPolicy {
  static const int maxElapsedMilliseconds = 24 * 60 * 60 * 1000;
}
