import 'package:flutter/foundation.dart';

/// Modelo imutável que representa uma corrida histórica completa
/// com data, horário, gastos e ganhos.
@immutable
class RideHistory {
  /// Data e hora da corrida
  final DateTime dateTime;

  /// Distância percorrida em quilômetros
  final double distanceKm;

  /// Custo total de combustível em Reais (R$)
  final double fuelCost;

  /// Custo total de manutenção em Reais (R$)
  final double maintenanceCost;

  /// Custo operacional total em Reais (R$)
  final double totalOperationalCost;

  /// Valor bruto cobrado em Reais (R$)
  final double grossAmount;

  /// Lucro líquido em Reais (R$)
  final double netProfit;

  /// Identificador único da corrida
  final String id;

  const RideHistory({
    required this.dateTime,
    required this.distanceKm,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.totalOperationalCost,
    required this.grossAmount,
    required this.netProfit,
    required this.id,
  });

  /// Factory que cria uma instância de RideHistory a partir dos dados da corrida atual
  factory RideHistory.fromRideData({
    required DateTime dateTime,
    required double distanceKm,
    required double fuelCost,
    required double maintenanceCost,
    required double totalOperationalCost,
    required double grossAmount,
    required double netProfit,
  }) {
    return RideHistory(
      dateTime: dateTime,
      distanceKm: distanceKm,
      fuelCost: fuelCost,
      maintenanceCost: maintenanceCost,
      totalOperationalCost: totalOperationalCost,
      grossAmount: grossAmount,
      netProfit: netProfit,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Converte o objeto para um mapa JSON para persistência
  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'distanceKm': distanceKm,
      'fuelCost': fuelCost,
      'maintenanceCost': maintenanceCost,
      'totalOperationalCost': totalOperationalCost,
      'grossAmount': grossAmount,
      'netProfit': netProfit,
      'id': id,
    };
  }

  /// Cria uma instância a partir de um mapa JSON
  factory RideHistory.fromJson(Map<String, dynamic> json) {
    return RideHistory(
      dateTime: DateTime.parse(json['dateTime'] as String),
      distanceKm: json['distanceKm'] as double,
      fuelCost: json['fuelCost'] as double,
      maintenanceCost: json['maintenanceCost'] as double,
      totalOperationalCost: json['totalOperationalCost'] as double,
      grossAmount: json['grossAmount'] as double,
      netProfit: json['netProfit'] as double,
      id: json['id'] as String,
    );
  }

  /// Retorna uma cópia com os campos especificados modificados
  RideHistory copyWith({
    DateTime? dateTime,
    double? distanceKm,
    double? fuelCost,
    double? maintenanceCost,
    double? totalOperationalCost,
    double? grossAmount,
    double? netProfit,
    String? id,
  }) {
    return RideHistory(
      dateTime: dateTime ?? this.dateTime,
      distanceKm: distanceKm ?? this.distanceKm,
      fuelCost: fuelCost ?? this.fuelCost,
      maintenanceCost: maintenanceCost ?? this.maintenanceCost,
      totalOperationalCost: totalOperationalCost ?? this.totalOperationalCost,
      grossAmount: grossAmount ?? this.grossAmount,
      netProfit: netProfit ?? this.netProfit,
      id: id ?? this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideHistory &&
        other.dateTime == dateTime &&
        other.distanceKm == distanceKm &&
        other.fuelCost == fuelCost &&
        other.maintenanceCost == maintenanceCost &&
        other.totalOperationalCost == totalOperationalCost &&
        other.grossAmount == grossAmount &&
        other.netProfit == netProfit &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(
        dateTime,
        distanceKm,
        fuelCost,
        maintenanceCost,
        totalOperationalCost,
        grossAmount,
        netProfit,
        id,
      );

  @override
  String toString() {
    return 'RideHistory('
        'dateTime: $dateTime, '
        'distanceKm: ${distanceKm.toStringAsFixed(2)}, '
        'fuelCost: R\$${fuelCost.toStringAsFixed(2)}, '
        'maintenanceCost: R\$${maintenanceCost.toStringAsFixed(2)}, '
        'totalOperationalCost: R\$${totalOperationalCost.toStringAsFixed(2)}, '
        'grossAmount: R\$${grossAmount.toStringAsFixed(2)}, '
        'netProfit: R\$${netProfit.toStringAsFixed(2)}, '
        'id: $id)';
  }
}
