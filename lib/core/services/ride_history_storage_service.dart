import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ride_calculator/domain/models/ride_history.dart';

/// Serviço responsável por persistir e recuperar o histórico de corridas
/// via [SharedPreferences].
class RideHistoryStorageService {
  final SharedPreferences _prefs;

  static const String _keyRideHistory = 'ride_history';

  RideHistoryStorageService(this._prefs);

  /// Salva uma nova corrida no histórico
  Future<bool> saveRide(RideHistory ride) async {
    final currentHistory = await loadRideHistory();
    final updatedHistory = [ride, ...currentHistory];
    
    return await _saveRideHistoryList(updatedHistory);
  }

  /// Salva uma lista completa de corridas no histórico
  Future<bool> _saveRideHistoryList(List<RideHistory> rides) async {
    final String encodedData = json.encode(
      rides.map((ride) => ride.toJson()).toList(),
    );
    return await _prefs.setString(_keyRideHistory, encodedData);
  }

  /// Carrega todas as corridas do histórico
  Future<List<RideHistory>> loadRideHistory() async {
    final String? encodedData = _prefs.getString(_keyRideHistory);
    
    if (encodedData == null || encodedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = json.decode(encodedData);
      return decodedList
          .map((item) => RideHistory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Em caso de erro na leitura, retorna lista vazia
      return [];
    }
  }

  /// Remove uma corrida específica do histórico pelo ID
  Future<bool> deleteRide(String rideId) async {
    final currentHistory = await loadRideHistory();
    final updatedHistory = currentHistory.where((ride) => ride.id != rideId).toList();
    return await _saveRideHistoryList(updatedHistory);
  }

  /// Remove todas as corridas do histórico
  Future<bool> clearAllHistory() async {
    return await _prefs.remove(_keyRideHistory);
  }

  /// Retorna estatísticas do histórico
  Future<RideHistoryStats> getHistoryStats() async {
    final history = await loadRideHistory();
    
    if (history.isEmpty) {
      return const RideHistoryStats();
    }

    final totalDistance = history.fold<double>(
      0.0,
      (sum, ride) => sum + ride.distanceKm,
    );

    final totalGross = history.fold<double>(
      0.0,
      (sum, ride) => sum + ride.grossAmount,
    );

    final totalOperationalCost = history.fold<double>(
      0.0,
      (sum, ride) => sum + ride.totalOperationalCost,
    );

    final totalNetProfit = history.fold<double>(
      0.0,
      (sum, ride) => sum + ride.netProfit,
    );

    return RideHistoryStats(
      totalRides: history.length,
      totalDistanceKm: totalDistance,
      totalGrossAmount: totalGross,
      totalOperationalCost: totalOperationalCost,
      totalNetProfit: totalNetProfit,
    );
  }
}

/// Modelo de estatísticas do histórico de corridas
class RideHistoryStats {
  final int totalRides;
  final double totalDistanceKm;
  final double totalGrossAmount;
  final double totalOperationalCost;
  final double totalNetProfit;

  const RideHistoryStats({
    this.totalRides = 0,
    this.totalDistanceKm = 0.0,
    this.totalGrossAmount = 0.0,
    this.totalOperationalCost = 0.0,
    this.totalNetProfit = 0.0,
  });

  /// Retorna a média de lucro por corrida
  double get averageProfitPerRide {
    if (totalRides == 0) return 0.0;
    return totalNetProfit / totalRides;
  }

  /// Retorna a média de distância por corrida
  double get averageDistancePerRide {
    if (totalRides == 0) return 0.0;
    return totalDistanceKm / totalRides;
  }

  /// Retorna a margem de lucro média em porcentagem
  double get averageProfitMargin {
    if (totalGrossAmount == 0) return 0.0;
    return (totalNetProfit / totalGrossAmount) * 100;
  }
}
