import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de dados contendo as métricas operacionais salvas do veículo.
class OperationalCostData {
  final double fuelConsumptionKmPerLiter;
  final double fuelPricePerLiter;
  final double maintenanceCostPerKm;
  final double tariffPerKm;

  const OperationalCostData({
    required this.fuelConsumptionKmPerLiter,
    required this.fuelPricePerLiter,
    required this.maintenanceCostPerKm,
    required this.tariffPerKm,
  });
}

/// Serviço responsável por persistir e recuperar os custos operacionais do veículo
/// (Consumo km/L, Preço R$/L, Manutenção R$/km e Tarifa R$/km) via [SharedPreferences].
class OperationalCostStorageService {
  final SharedPreferences _prefs;

  static const String _keyFuelConsumption = 'operational_fuel_consumption';
  static const String _keyFuelPrice = 'operational_fuel_price';
  static const String _keyMaintenanceCost = 'operational_maintenance_cost';
  static const String _keyTariffPerKm = 'operational_tariff_per_km';

  // Valores padrão iniciais de fábrica
  static const double defaultFuelConsumption = 10.0;
  static const double defaultFuelPrice = 5.50;
  static const double defaultMaintenanceCost = 0.30;
  static const double defaultTariffPerKm = 2.50;

  OperationalCostStorageService(this._prefs);

  /// Salva as configurações de custo operacional no armazenamento local.
  Future<bool> saveOperationalCosts({
    required double fuelConsumptionKmPerLiter,
    required double fuelPricePerLiter,
    required double maintenanceCostPerKm,
    required double tariffPerKm,
  }) async {
    final results = await Future.wait([
      _prefs.setDouble(_keyFuelConsumption, fuelConsumptionKmPerLiter),
      _prefs.setDouble(_keyFuelPrice, fuelPricePerLiter),
      _prefs.setDouble(_keyMaintenanceCost, maintenanceCostPerKm),
      _prefs.setDouble(_keyTariffPerKm, tariffPerKm),
    ]);
    return !results.contains(false);
  }

  /// Carrega as configurações salvas do dispositivo ou retorna os padrões.
  OperationalCostData loadOperationalCosts() {
    return OperationalCostData(
      fuelConsumptionKmPerLiter:
          _prefs.getDouble(_keyFuelConsumption) ?? defaultFuelConsumption,
      fuelPricePerLiter:
          _prefs.getDouble(_keyFuelPrice) ?? defaultFuelPrice,
      maintenanceCostPerKm:
          _prefs.getDouble(_keyMaintenanceCost) ?? defaultMaintenanceCost,
      tariffPerKm:
          _prefs.getDouble(_keyTariffPerKm) ?? defaultTariffPerKm,
    );
  }

  /// Remove os dados salvos localmente e restaura os padrões de fábrica.
  Future<bool> clearOperationalCosts() async {
    final results = await Future.wait([
      _prefs.remove(_keyFuelConsumption),
      _prefs.remove(_keyFuelPrice),
      _prefs.remove(_keyMaintenanceCost),
      _prefs.remove(_keyTariffPerKm),
    ]);
    return !results.contains(false);
  }
}
