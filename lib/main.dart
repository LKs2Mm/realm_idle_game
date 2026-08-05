import 'package:flutter/material.dart';
import 'package:realm_idle_game/app/realm_idle_app.dart';
import 'package:realm_idle_game/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.initialize();
  runApp(const RealmIdleApp());
}
