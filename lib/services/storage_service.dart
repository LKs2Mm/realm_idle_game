import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realm_idle_game/models/game_state.dart';

class StorageService {
  static const String _gameStateKey = 'game_state';
  static late SharedPreferences _prefs;
  static Future<void> _saveQueue = Future<void>.value();

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveGameState(GameState gameState) async {
    final json = jsonEncode(gameState.toJson());
    final operation = _saveQueue.then((_) async {
      await _prefs.setString(_gameStateKey, json);
    });
    _saveQueue = operation.catchError((Object _) {});
    await operation;
  }

  static Future<GameState?> loadGameState() async {
    final json = _prefs.getString(_gameStateKey);
    if (json == null) return null;

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return GameState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearGameState() async {
    await _saveQueue;
    await _prefs.remove(_gameStateKey);
  }
}
