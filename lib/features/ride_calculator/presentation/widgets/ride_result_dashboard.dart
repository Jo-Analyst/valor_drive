import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../controllers/ride_signal_controller.dart';

/// Dashboard visualmente impactante para o motorista avaliar a rentabilidade da corrida.
///
/// Destaca a diferença crítica entre Custo Operacional (Alerta em Laranja/Vermelho)
/// e Lucro Líquido (Verde Vibrante / Rentabilidade).
class RideResultDashboard extends StatelessWidget {
  final RideSignalController controller;

  const RideResultDashboard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final result = controller.rideResult.watch(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );

    // Cores de status de rentabilidade
    final isProfitable = result.netProfit > 0;
    final isZero = result.grossAmount == 0;

    final profitColor = isZero
        ? theme.colorScheme.onSurfaceVariant
        : isProfitable
            ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32))
            : theme.colorScheme.error;

    final profitBgColor = isZero
        ? theme.colorScheme.surfaceContainerHighest
        : isProfitable
            ? (isDark ? const Color(0xFF1B381E) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF3E1A1A) : const Color(0xFFFFEBEE));

    final costColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    final costBgColor =
        isDark ? const Color(0xFF33200A) : const Color(0xFFFFF3E0);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===============================================================
              // DESTAQUE 1: LUCRO LÍQUIDO (CARD DE RENTABILIDADE PRINCIPAL)
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: profitBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: profitColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isProfitable
                              ? Icons.payments_rounded
                              : Icons.warning_amber_rounded,
                          color: profitColor,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'LUCRO LÍQUIDO',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: profitColor,
                              letterSpacing: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isZero) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: profitColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${result.profitMarginPercentage.toStringAsFixed(1)}% Margem',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currencyFormat.format(result.netProfit),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: profitColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isZero
                          ? 'Informe a distância e tarifa'
                          : (isProfitable
                              ? '✓ Corrida lucrativa para o bolso'
                              : '⚠️ Atenção: Corrida no prejuízo!'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: profitColor.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===============================================================
              // DESTAQUE 2: CUSTO OPERACIONAL TOTAL (ALERTA EM LARANJA/VERMELHO)
              // ===============================================================
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: costBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: costColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: costColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.trending_down_rounded,
                        color: costColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CUSTO OPERACIONAL TOTAL',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: costColor,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Combustível + Manutenção',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        currencyFormat.format(result.totalOperationalCost),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: costColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===============================================================
              // DETALHAMENTO: COMBUSTÍVEL, MANUTENÇÃO E VALOR BRUTO
              // ===============================================================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      icon: Icons.local_gas_station_rounded,
                      label: 'Custo de Combustível',
                      value: currencyFormat.format(result.fuelCost),
                      iconColor: Colors.amber.shade800,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.build_circle_rounded,
                      label: 'Custo de Manutenção',
                      value: currencyFormat.format(result.maintenanceCost),
                      iconColor: Colors.blueGrey,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    _buildDetailRow(
                      context,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Valor Bruto a Cobrar',
                      value: currencyFormat.format(result.grossAmount),
                      iconColor: theme.colorScheme.primary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
