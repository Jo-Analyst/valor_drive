import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../../features/ride_calculator/domain/enums/calculation_mode.dart';
import '../../features/ride_calculator/presentation/controllers/ride_signal_controller.dart';

/// Serviço responsável por capturar o sinal de GPS e calcular a distância
/// percorrida acumulada em tempo real, atualizando o [RideSignalController].
class GpsTrackingService {
  final RideSignalController _controller;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Map<String, dynamic>?>? _backgroundUpdateSubscription;
  final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  Position? _lastPosition;
  double _accumulatedDistanceMeters = 0.0;

  /// Sinal que indica se o rastreamento GPS está ativo no momento.
  final Signal<bool> isTrackingSignal = signal<bool>(false);

  /// Sinal com o status legível da conexão de GPS.
  final Signal<String> gpsStatusSignal = signal<String>('GPS Inativo');

  /// Sinal com a lista de coordenadas geográfica (LatLng) percorridas na rota.
  final Signal<List<LatLng>> routePointsSignal = signal<List<LatLng>>([]);

  GpsTrackingService(this._controller) {
    if (Platform.isAndroid) {
      _backgroundUpdateSubscription = _backgroundService.on('gpsUpdate').listen(
        (event) {
          final distanceKm = (event?['distanceKm'] as num?)?.toDouble();
          if (distanceKm != null) {
            _controller.updateGpsDistance(distanceKm);
          }

          final latitude = (event?['latitude'] as num?)?.toDouble();
          final longitude = (event?['longitude'] as num?)?.toDouble();
          if (latitude != null && longitude != null) {
            routePointsSignal.value = [
              ...routePointsSignal.value,
              LatLng(latitude, longitude),
            ];
          }
        },
      );
    }
  }

  /// Inicia o rastreamento em tempo real da posição GPS.
  Future<bool> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verifica se os serviços de localização estão habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      gpsStatusSignal.value = 'GPS Desativado no Dispositivo';
      isTrackingSignal.value = false;
      return false;
    }

    // 2. Verifica permissão de acesso à localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        gpsStatusSignal.value = 'Permissão de GPS Negada';
        isTrackingSignal.value = false;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      gpsStatusSignal.value = 'Permissão de GPS Bloqueada';
      isTrackingSignal.value = false;
      return false;
    }

    // 3. Cancela assinatura anterior se existente
    await _positionSubscription?.cancel();

    gpsStatusSignal.value = 'Conectando ao GPS...';

    try {
      // Obtém posição inicial
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final initialPoint = LatLng(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
      );
      if (routePointsSignal.value.isEmpty) {
        routePointsSignal.value = [initialPoint];
      }

      // Alterna automaticamente o controller para o modo GPS
      _controller.setCalculationMode(CalculationMode.gps);

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Atualiza a cada 5 metros percorridos
      );

      _positionSubscription = Platform.isAndroid
          ? null
          : Geolocator.getPositionStream(
              locationSettings: locationSettings,
            ).listen(
              (Position newPosition) {
                final newPoint = LatLng(
                  newPosition.latitude,
                  newPosition.longitude,
                );

                if (_lastPosition != null) {
                  final distanceBetweenMeters = Geolocator.distanceBetween(
                    _lastPosition!.latitude,
                    _lastPosition!.longitude,
                    newPosition.latitude,
                    newPosition.longitude,
                  );

                  _accumulatedDistanceMeters += distanceBetweenMeters;
                  final km = _accumulatedDistanceMeters / 1000.0;

                  // Atualiza reativamente o sinal de distância GPS no Controller
                  _controller.updateGpsDistance(km);
                }

                routePointsSignal.value = [
                  ...routePointsSignal.value,
                  newPoint,
                ];
                _lastPosition = newPosition;
                gpsStatusSignal.value = 'Rastreando em Tempo Real';
              },
              onError: (error) {
                gpsStatusSignal.value = 'Erro no Sinal de GPS';
                isTrackingSignal.value = false;
              },
            );

      if (Platform.isAndroid) {
        if (!await _backgroundService.isRunning()) {
          await _backgroundService.startService();
        }
        _backgroundService.invoke('startGpsTracking', {
          'distanceKm': _accumulatedDistanceMeters / 1000,
        });
      }

      isTrackingSignal.value = true;
      gpsStatusSignal.value = 'Rastreando em Tempo Real';
      return true;
    } catch (e) {
      gpsStatusSignal.value = 'Falha ao Iniciar GPS';
      isTrackingSignal.value = false;
      return false;
    }
  }

  /// Pausa a escuta de coordenadas do GPS.
  Future<void> pauseTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    if (Platform.isAndroid) {
      _backgroundService.invoke('stopGpsTracking');
    }
    isTrackingSignal.value = false;
    gpsStatusSignal.value = 'GPS Pausado';
  }

  /// Reinicia o hodômetro de GPS para 0.0 KM e limpa os pontos no mapa.
  void resetTracking() {
    // Cancel any active GPS subscription without awaiting.
    _positionSubscription?.cancel();
    _positionSubscription = null;
    if (Platform.isAndroid) {
      _backgroundService.invoke('stopGpsTracking');
    }
    isTrackingSignal.value = false;
    _accumulatedDistanceMeters = 0.0;
    _lastPosition = null;
    routePointsSignal.value = [];
    _controller.updateGpsDistance(0.0);
    gpsStatusSignal.value = 'GPS Zerado';
  }

  /// Simulação de incremento manual de distância GPS (útil para testes/desenvolvimento).
  void simulateDistanceIncrement(double addKm) {
    _accumulatedDistanceMeters += (addKm * 1000.0);
    final currentKm = _accumulatedDistanceMeters / 1000.0;
    _controller.updateGpsDistance(currentKm);
    _controller.setCalculationMode(CalculationMode.gps);

    final currentPoints = List<LatLng>.from(routePointsSignal.value);
    final basePoint = currentPoints.isNotEmpty
        ? currentPoints.last
        : const LatLng(-23.550520, -46.633308); // Padrão centro de SP

    if (currentPoints.isEmpty) {
      currentPoints.add(basePoint);
    }

    final nextLat = basePoint.latitude + (0.003 * addKm);
    final nextLng = basePoint.longitude + (0.004 * addKm);
    currentPoints.add(LatLng(nextLat, nextLng));

    routePointsSignal.value = currentPoints;
    gpsStatusSignal.value = 'GPS Simulado (+${addKm}km)';
  }

  void dispose() {
    _positionSubscription?.cancel();
    _backgroundUpdateSubscription?.cancel();
    isTrackingSignal.dispose();
    gpsStatusSignal.dispose();
    routePointsSignal.dispose();
  }
}
