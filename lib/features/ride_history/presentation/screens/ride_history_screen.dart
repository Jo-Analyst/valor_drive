import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/ride_history_storage_service.dart';
import '../../../ride_calculator/domain/models/ride_history.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  late final RideHistoryStorageService _historyService;
  late Future<List<RideHistory>> _ridesFuture;
  late Future<RideHistoryStats> _statsFuture;

  DateTime? _selectedMonth;
  List<RideHistory> _allRides = [];
  List<RideHistory> _filteredRides = [];

  @override
  void initState() {
    super.initState();
    _historyService = getIt<RideHistoryStorageService>();
    _ridesFuture = Future.value(const <RideHistory>[]);
    _statsFuture = Future.value(const RideHistoryStats());
    _loadData();
  }

  Future<void> _loadData() async {
    _ridesFuture = _historyService.loadRideHistory();
    _allRides = await _ridesFuture;
    _filteredRides = _filterRidesByMonth(_allRides, _selectedMonth);
    _statsFuture = _calculateStatsForFilteredRides();
    if (mounted) setState(() {});
  }

  List<RideHistory> _filterRidesByMonth(
    List<RideHistory> rides,
    DateTime? month,
  ) {
    if (month == null) return rides;

    return rides.where((ride) {
      return ride.dateTime.year == month.year &&
          ride.dateTime.month == month.month;
    }).toList();
  }

  Future<RideHistoryStats> _calculateStatsForFilteredRides() async {
    if (_filteredRides.isEmpty) {
      return const RideHistoryStats();
    }

    final totalDistance = _filteredRides.fold<double>(
      0.0,
      (sum, ride) => sum + ride.distanceKm,
    );

    final totalGross = _filteredRides.fold<double>(
      0.0,
      (sum, ride) => sum + ride.grossAmount,
    );

    final totalOperationalCost = _filteredRides.fold<double>(
      0.0,
      (sum, ride) => sum + ride.totalOperationalCost,
    );

    final totalNetProfit = _filteredRides.fold<double>(
      0.0,
      (sum, ride) => sum + ride.netProfit,
    );

    return RideHistoryStats(
      totalRides: _filteredRides.length,
      totalDistanceKm: totalDistance,
      totalGrossAmount: totalGross,
      totalOperationalCost: totalOperationalCost,
      totalNetProfit: totalNetProfit,
    );
  }

  void _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Selecione o mês e ano',
      confirmText: 'Filtrar',
      cancelText: 'Cancelar',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
        _filteredRides = _filterRidesByMonth(_allRides, _selectedMonth);
        _statsFuture = _calculateStatsForFilteredRides();
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedMonth = null;
      _filteredRides = _allRides;
      _statsFuture = _calculateStatsForFilteredRides();
    });
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _deleteRide(String rideId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
          'Deseja realmente excluir esta corrida do histórico?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.deleteRide(rideId);
      await _refreshData();
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar todo o histórico'),
        content: const Text(
          'Deseja realmente excluir todas as corridas do histórico? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearAllHistory();
      await _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Corridas'),
        actions: [
          if (_selectedMonth != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Limpar filtro',
              onPressed: _clearFilter,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por mês',
            onPressed: _selectMonth,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar histórico',
            onPressed: _clearAllHistory,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              _buildStatsSection(),
              Expanded(child: _buildRidesList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return FutureBuilder<RideHistoryStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        if (stats.totalRides == 0) {
          return const SizedBox.shrink();
        }

        final monthNames = [
          'Janeiro',
          'Fevereiro',
          'Março',
          'Abril',
          'Maio',
          'Junho',
          'Julho',
          'Agosto',
          'Setembro',
          'Outubro',
          'Novembro',
          'Dezembro',
        ];
        final periodText = _selectedMonth != null
            ? '${monthNames[_selectedMonth!.month - 1]}/${_selectedMonth!.year}'
            : 'Todos os períodos';

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resumo do Histórico',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedMonth != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        periodText,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Total de Corridas',
                      value: stats.totalRides.toString(),
                      icon: Icons.directions_car,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Distância Total',
                      value: '${stats.totalDistanceKm.toStringAsFixed(1)} km',
                      icon: Icons.route,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Gastos Totais',
                      value:
                          'R\$${stats.totalOperationalCost.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      valueColor: Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Ganhos Totais',
                      value: 'R\$${stats.totalGrossAmount.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      valueColor: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'Lucro Líquido',
                      value: 'R\$${stats.totalNetProfit.toStringAsFixed(2)}',
                      icon: Icons.trending_up,
                      valueColor: stats.totalNetProfit >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ), // Espaço vazio para alinhamento
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRidesList() {
    return FutureBuilder<List<RideHistory>>(
      future: _ridesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar histórico',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final rides = _filteredRides;

        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selectedMonth != null ? Icons.search_off : Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedMonth != null
                      ? 'Nenhuma corrida encontrada neste período'
                      : 'Nenhuma corrida registrada',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedMonth != null
                      ? 'Tente selecionar outro período'
                      : 'As corridas salvas aparecerão aqui',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _RideCard(ride: ride, onDelete: () => _deleteRide(ride.id));
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideHistory ride;
  final VoidCallback onDelete;

  const _RideCard({required this.ride, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.directions_car,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          '${dateFormat.format(ride.dateTime)} - ${timeFormat.format(ride.dateTime)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 14,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Comb: R\$${ride.fuelCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.build, size: 14, color: Colors.red[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Manut: R\$${ride.maintenanceCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bruto: R\$${ride.grossAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: ride.netProfit >= 0
                          ? Colors.green[700]
                          : Colors.red[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Líq: R\$${ride.netProfit.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: ride.netProfit >= 0
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ride.gpsRoute.isNotEmpty) ...[
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: ride.gpsRoute.first,
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.valor_drive',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: ride.gpsRoute,
                                strokeWidth: 4.0,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              if (ride.gpsRoute.isNotEmpty)
                                Marker(
                                  point: ride.gpsRoute.first,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                ),
                              if (ride.gpsRoute.length > 1)
                                Marker(
                                  point: ride.gpsRoute.last,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.flag,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                ],
                _buildDetailRow(
                  context,
                  'Distância',
                  '${ride.distanceKm.toStringAsFixed(2)} km',
                  Icons.route,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  'Custo Combustível',
                  'R\$${ride.fuelCost.toStringAsFixed(2)}',
                  Icons.local_gas_station,
                  valueColor: Colors.red[700],
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  'Custo Manutenção',
                  'R\$${ride.maintenanceCost.toStringAsFixed(2)}',
                  Icons.build,
                  valueColor: Colors.red[700],
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  'Custo Operacional Total',
                  'R\$${ride.totalOperationalCost.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  valueColor: Colors.red[700],
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  context,
                  'Valor Bruto Cobrado',
                  'R\$${ride.grossAmount.toStringAsFixed(2)}',
                  Icons.attach_money,
                  valueColor: Colors.green[700],
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  'Lucro Líquido',
                  'R\$${ride.netProfit.toStringAsFixed(2)}',
                  Icons.trending_up,
                  valueColor: ride.netProfit >= 0
                      ? Colors.green[700]
                      : Colors.red[700],
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey[700])),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
