import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Serviço estático de notificações locais. Assim como `AudioService`, toda
/// chamada é silenciosamente descartada em caso de erro — plugin
/// indisponível (testes de widget), permissão negada pelo usuário, ou
/// agendamento rejeitado pela plataforma — para que notificações nunca
/// derrubem o app ou quebrem um teste.
abstract final class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int _productionCompleteId = 1;
  static const int _returnReminderId = 2;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        'realm_idle_reminders',
        'Lembretes do reino',
        channelDescription:
            'Avisos de produção concluída e de retorno ao jogo.',
        importance: Importance.defaultImportance,
      );

  static Future<void> initialize() async {
    if (_initialized) return;
    await _safe(() async {
      tz_data.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
    });
  }

  static Future<void> requestPermission() async {
    await _safe(() async {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    });
  }

  static Future<void> scheduleProductionComplete(Duration delay) {
    return _scheduleOnce(
      id: _productionCompleteId,
      title: 'Produção concluída',
      body:
          'Sua oficina terminou de trabalhar. Volte pra coletar o resultado.',
      delay: delay,
    );
  }

  static Future<void> scheduleReturnReminder(Duration delay) {
    return _scheduleOnce(
      id: _returnReminderId,
      title: 'O reino sente sua falta',
      body: 'Seu herói está parado há um tempo. Volte pra continuar a jornada.',
      delay: delay,
    );
  }

  static Future<void> cancelAll() async {
    await _safe(() => _plugin.cancelAll());
  }

  static Future<void> _scheduleOnce({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    await _safe(() async {
      final scheduledDate = tz.TZDateTime.now(tz.UTC).add(delay);
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: _androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });
  }

  static Future<void> _safe(FutureOr<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Sem plugin disponível (testes), permissão negada, ou agendamento
      // rejeitado — falha silenciosa, nunca deve interromper o app.
    }
  }
}
