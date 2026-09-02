import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/gps_tracking_service.dart';
import '../../domain/enums/calculation_mode.dart';
import '../controllers/ride_signal_controller.dart';

/// Componente de seleção de modo de cálculo (GPS vs Entrada Manual) com
/// controles em tempo real do serviço de GPS via [GetIt].
class CalculationModeSelector extends StatelessWidget {
  final RideSignalController controller;

  const CalculationModeSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final currentMode = controller.calculationModeSignal.watch(context);
    final gpsService = getIt<GpsTrackingService>();
    final isTracking = gpsService.isTrackingSignal.watch(context);
    final gpsStatus = gpsService.gpsStatusSignal.watch(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Modo de Medição',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (currentMode == CalculationMode.gps) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isTracking
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTracking
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTracking ? Icons.sensors : Icons.sensors_off,
                      size: 14,
                      color: isTracking
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gpsStatus,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isTracking
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<CalculationMode>(
            segments: const [
              ButtonSegment<CalculationMode>(
                value: CalculationMode.manual,
                label: Text('Média Manual (KM)'),
                icon: Icon(Icons.edit_road_rounded),
              ),
              ButtonSegment<CalculationMode>(
                value: CalculationMode.gps,
                label: Text('Modo GPS'),
                icon: Icon(Icons.gps_fixed_rounded),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (Set<CalculationMode> newSelection) async {
              if (newSelection.isNotEmpty) {
                final selected = newSelection.first;

                if (selected == CalculationMode.gps) {
                  // Verifica se o GPS está desativado
                  bool serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    // Mostra diálogo pedindo para ativar o GPS
                    if (context.mounted) {
                      final shouldOpenSettings = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('GPS Desativado'),
                          content: const Text(
                            'Para usar o modo GPS, você precisa ativar o serviço de localização do dispositivo. Deseja abrir as configurações?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Abrir Configurações'),
                            ),
                          ],
                        ),
                      );

                      if (shouldOpenSettings == true) {
                        await Geolocator.openLocationSettings();
                        // Volta para o modo manual se o usuário cancelar
                        controller.setCalculationMode(CalculationMode.manual);
                        return;
                      } else {
                        // Volta para o modo manual se o usuário cancelar
                        controller.setCalculationMode(CalculationMode.manual);
                        return;
                      }
                    }
                  }
                }

                controller.setCalculationMode(selected);
                if (selected == CalculationMode.gps && !isTracking) {
                  gpsService.startTracking();
                }
              }
            },
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              visualDensity: VisualDensity.comfortable,
            ),
          ),
        ),

        // CONTROLES DE RASTREAMENTO GPS EM TEMPO REAL
        if (currentMode == CalculationMode.gps) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isTracking
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primary,
                      foregroundColor: isTracking
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (isTracking) {
                        gpsService.pauseTracking();
                      } else {
                        gpsService.startTracking();
                      }
                    },
                    icon: Icon(
                      isTracking
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                    ),
                    label: Text(isTracking ? 'Pausar GPS' : 'Iniciar GPS'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Zerar Hodômetro GPS',
                  onPressed: () => gpsService.resetTracking(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                PopupMenuButton<double>(
                  tooltip: 'Simular movimento GPS (+KM)',
                  icon: const Icon(Icons.speed_rounded),
                  onSelected: (addKm) {
                    gpsService.simulateDistanceIncrement(addKm);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 1.0,
                      child: Text('Simular +1.0 km'),
                    ),
                    const PopupMenuItem(
                      value: 5.0,
                      child: Text('Simular +5.0 km'),
                    ),
                    const PopupMenuItem(
                      value: 10.0,
                      child: Text('Simular +10.0 km'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
