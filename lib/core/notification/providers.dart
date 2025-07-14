import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_wave/core/notification/notification_service.dart';

final notificationServiceProvider = FutureProvider<NotificationService>((ref) async {
  var service = NotificationService();
  await service.initialize();
  await service.settingHandler();
  return service;
});
