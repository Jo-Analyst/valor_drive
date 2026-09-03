import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

const _notificationId = 4101;

Future<void> initializeBackgroundExecution() async {
  final service = FlutterBackgroundService();

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: backgroundServiceEntryPoint,
      onBackground: iosBackgroundEntryPoint,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundServiceEntryPoint,
      autoStart: false,
      autoStartOnBoot: false,
      isForegroundMode: true,
      initialNotificationTitle: 'ValorDrive ativo',
      initialNotificationContent: 'O acompanhamento continua em segundo plano',
      foregroundServiceNotificationId: _notificationId,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> iosBackgroundEntryPoint(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void backgroundServiceEntryPoint(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  StreamSubscription<Position>? gpsSubscription;
  var accumulatedDistanceMeters = 0.0;
  Position? lastPosition;

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (service is AndroidServiceInstance &&
        !await service.isForegroundService()) {
      timer.cancel();
      return;
    }

    service.invoke('backgroundHeartbeat', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  service.on('stopService').listen((event) {
    gpsSubscription?.cancel();
    service.stopSelf();
  });

  service.on('startGpsTracking').listen((event) {
    gpsSubscription?.cancel();
    accumulatedDistanceMeters =
        ((event?['distanceKm'] as num?)?.toDouble() ?? 0.0) * 1000;
    lastPosition = null;

    gpsSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (lastPosition != null) {
            accumulatedDistanceMeters += Geolocator.distanceBetween(
              lastPosition!.latitude,
              lastPosition!.longitude,
              position.latitude,
              position.longitude,
            );
          }
          lastPosition = position;
          service.invoke('gpsUpdate', {
            'distanceKm': accumulatedDistanceMeters / 1000,
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
        });
  });

  service.on('stopGpsTracking').listen((event) async {
    await gpsSubscription?.cancel();
    gpsSubscription = null;
    lastPosition = null;
  });
}
