import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/gps_tracking_service.dart';

/// Widget de mapa interativo que desenha a rota percorrida pelo motorista
/// em tempo real utilizando [flutter_map] e OpenStreetMap.
class RideGpsMapWidget extends StatefulWidget {
  const RideGpsMapWidget({super.key});

  @override
  State<RideGpsMapWidget> createState() => _RideGpsMapWidgetState();
}

class _RideGpsMapWidgetState extends State<RideGpsMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerMapOnCurrentPosition(List<LatLng> points) {
    if (points.isNotEmpty) {
      _mapController.move(points.last, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gpsService = getIt<GpsTrackingService>();
    final routePoints = gpsService.routePointsSignal.watch(context);
    final isTracking = gpsService.isTrackingSignal.watch(context);
    final statusText = gpsService.gpsStatusSignal.watch(context);
    final theme = Theme.of(context);

    // Centro padrão (São Paulo caso ainda não haja rota capturada)
    final defaultCenter = const LatLng(-23.550520, -46.633308);
    final initialCenter =
        routePoints.isNotEmpty ? routePoints.last : defaultCenter;

    final startPoint = routePoints.isNotEmpty ? routePoints.first : null;
    final currentPoint = routePoints.isNotEmpty ? routePoints.last : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Percurso Rasteado em Tempo Real',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isTracking
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${routePoints.length} pontos',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isTracking
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // CONTAINER DO MAPA
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    // Camada de Tiles OpenStreetMap
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.valordrive.app',
                    ),

                    // Camada da Linha da Rota (Polyline)
                    if (routePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 5.0,
                            color: theme.colorScheme.primary,
                            borderStrokeWidth: 2.0,
                            borderColor: theme.colorScheme.surface,
                          ),
                        ],
                      ),

                    // Camada de Marcadores (Início e Posição Atual)
                    MarkerLayer(
                      markers: [
                        // Marcador de Origem (Início da Corrida)
                        if (startPoint != null)
                          Marker(
                            point: startPoint,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),

                        // Marcador de Posição Atual (Navegação)
                        if (currentPoint != null)
                          Marker(
                            point: currentPoint,
                            width: 38,
                            height: 38,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Se o mapa ainda não tiver pontos capturados
                if (routePoints.isEmpty)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black12,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Botão Flutuante de Centralização no Canto Superior Direito
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_gps_map_fab',
                    elevation: 3,
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    onPressed: () => _centerMapOnCurrentPosition(routePoints),
                    child: const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
