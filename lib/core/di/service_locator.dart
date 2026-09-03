import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gps_tracking_service.dart';
import '../services/operational_cost_storage_service.dart';
import '../services/ride_history_storage_service.dart';
import '../../features/ride_calculator/presentation/controllers/ride_signal_controller.dart';

/// Instância global do Service Locator [GetIt].
final GetIt getIt = GetIt.instance;

/// Inicializa e registra todas as dependências e controllers do projeto.
///
/// Esta função deve ser invocada na inicialização do aplicativo (`main.dart`).
Future<void> setupServiceLocator() async {
  // 1. Registra o SharedPreferences
  if (!getIt.isRegistered<SharedPreferences>()) {
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
  }

  // 2. Registra o OperationalCostStorageService (Persistência Local)
  if (!getIt.isRegistered<OperationalCostStorageService>()) {
    getIt.registerLazySingleton<OperationalCostStorageService>(
      () => OperationalCostStorageService(getIt<SharedPreferences>()),
    );
  }

  // 3. Registra o RideHistoryStorageService (Persistência de Histórico)
  if (!getIt.isRegistered<RideHistoryStorageService>()) {
    getIt.registerLazySingleton<RideHistoryStorageService>(
      () => RideHistoryStorageService(getIt<SharedPreferences>()),
    );
  }

  // 4. Registra o RideSignalController
  if (!getIt.isRegistered<RideSignalController>()) {
    getIt.registerLazySingleton<RideSignalController>(
      () => RideSignalController(
        getIt<OperationalCostStorageService>(),
        getIt<RideHistoryStorageService>(),
      ),
      dispose: (controller) => controller.dispose(),
    );
  }

  // 4. Registra o GpsTrackingService (Serviço de GPS)
  if (!getIt.isRegistered<GpsTrackingService>()) {
    getIt.registerLazySingleton<GpsTrackingService>(
      () => GpsTrackingService(getIt<RideSignalController>()),
      dispose: (service) => service.dispose(),
    );
  }
}
