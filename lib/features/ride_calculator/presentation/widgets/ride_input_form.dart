import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../domain/enums/calculation_mode.dart';
import '../controllers/ride_signal_controller.dart';
import 'ride_gps_map_widget.dart';

/// Formulário de entrada ultra rápido para o motorista inserir ou alterar
/// os dados operacionais do carro e da corrida.
class RideInputForm extends StatefulWidget {
  final RideSignalController controller;

  const RideInputForm({
    super.key,
    required this.controller,
  });

  @override
  State<RideInputForm> createState() => _RideInputFormState();
}

class _RideInputFormState extends State<RideInputForm> {
  late final TextEditingController _manualDistanceController;
  late final TextEditingController _gpsDistanceController;
  late final TextEditingController _fuelConsumptionController;
  late final TextEditingController _fuelPriceController;
  late final TextEditingController _maintenanceController;
  late final TextEditingController _tariffController;

  @override
  void initState() {
    super.initState();
    final ctrl = widget.controller;

    _manualDistanceController = TextEditingController(
      text: ctrl.manualDistanceKmSignal.value > 0
          ? ctrl.manualDistanceKmSignal.value.toString()
          : '',
    );

    _gpsDistanceController = TextEditingController(
      text: ctrl.gpsDistanceKmSignal.value > 0
          ? ctrl.gpsDistanceKmSignal.value.toStringAsFixed(2)
          : '',
    );

    _fuelConsumptionController = TextEditingController(
      text: ctrl.fuelConsumptionKmPerLiterSignal.value.toString(),
    );

    _fuelPriceController = TextEditingController(
      text: ctrl.fuelPricePerLiterSignal.value > 0
          ? ctrl.fuelPricePerLiterSignal.value.toStringAsFixed(2)
          : '',
    );

    _maintenanceController = TextEditingController(
      text: ctrl.maintenanceCostPerKmSignal.value > 0
          ? ctrl.maintenanceCostPerKmSignal.value.toStringAsFixed(2)
          : '',
    );

    _tariffController = TextEditingController(
      text: ctrl.tariffPerKmSignal.value > 0
          ? ctrl.tariffPerKmSignal.value.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _manualDistanceController.dispose();
    _gpsDistanceController.dispose();
    _fuelConsumptionController.dispose();
    _fuelPriceController.dispose();
    _maintenanceController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  double _parseInput(String text) {
    if (text.isEmpty) return 0.0;
    final sanitized = text.replaceAll(',', '.');
    return double.tryParse(sanitized) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.controller.calculationModeSignal.watch(context);
    final gpsDistance = widget.controller.gpsDistanceKmSignal.watch(context);
    final theme = Theme.of(context);

    // Sincroniza o controller de texto de GPS quando o sinal de GPS for atualizado pelo serviço
    if (mode == CalculationMode.gps &&
        _parseInput(_gpsDistanceController.text) != gpsDistance) {
      _gpsDistanceController.text =
          gpsDistance > 0 ? gpsDistance.toStringAsFixed(2) : '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parâmetros da Corrida',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 1. DISTÂNCIA (MANUAL OU GPS)
        if (mode == CalculationMode.manual) ...[
          TextFormField(
            controller: _manualDistanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Média de Distância a Percorrer (KM)',
              hintText: 'Ex: 12.5',
              prefixIcon: const Icon(Icons.straighten_rounded),
              suffixText: 'km',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
            ),
            onChanged: (value) {
              widget.controller.setManualDistance(_parseInput(value));
            },
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.my_location_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distância Rastreada via GPS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Atualizado dinamicamente pelo sinal de GPS',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _gpsDistanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Distância Acumulada GPS (KM)',
                    prefixIcon: const Icon(Icons.gps_fixed),
                    suffixText: 'km',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  onChanged: (value) {
                    widget.controller.updateGpsDistance(_parseInput(value));
                  },
                ),
                const SizedBox(height: 16),
                const RideGpsMapWidget(),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        Text(
          'Custos Operacionais do Veículo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 2. CONSUMO MÉDIO (KM/L) E PREÇO DO COMBUSTÍVEL (R$/L)
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fuelConsumptionController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Consumo (km/L)',
                  hintText: '10.0',
                  prefixIcon: const Icon(Icons.directions_car_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  widget.controller.setFuelConsumption(_parseInput(value));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _fuelPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: r'Gasolina (R$/L)',
                  hintText: '5.89',
                  prefixIcon: const Icon(Icons.local_gas_station_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  widget.controller.setFuelPrice(_parseInput(value));
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. CUSTO DE MANUTENÇÃO POR KM E TARIFA DESEJADA POR KM
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maintenanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: r'Manutenção (R$/km)',
                  hintText: '0.35',
                  prefixIcon: const Icon(Icons.build_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  widget.controller
                      .setMaintenanceCostPerKm(_parseInput(value));
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tariffController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: r'Tarifa (R$/km)',
                  hintText: '2.50',
                  prefixIcon: const Icon(Icons.sell_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  widget.controller.setTariffPerKm(_parseInput(value));
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // BOTÃO DE RESET RÁPIDO E ATALHOS
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () {
                widget.controller.reset();
                setState(() {
                  _manualDistanceController.text = '';
                  _gpsDistanceController.text = '';
                  _fuelConsumptionController.text = '10.0';
                  _fuelPriceController.text = '5.50';
                  _maintenanceController.text = '0.30';
                  _tariffController.text = '2.50';
                });
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Limpar Dados'),
            ),
            ActionChip(
              avatar: const Icon(Icons.flash_on_rounded, size: 14),
              label: const Text('Preencher Padrão'),
              onPressed: () {
                widget.controller.updateOperationalData(
                  fuelConsumptionKmPerLiter: 12.0,
                  fuelPricePerLiter: 5.89,
                  maintenanceCostPerKm: 0.35,
                  tariffPerKm: 2.80,
                );
                setState(() {
                  _fuelConsumptionController.text = '12.0';
                  _fuelPriceController.text = '5.89';
                  _maintenanceController.text = '0.35';
                  _tariffController.text = '2.80';
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
