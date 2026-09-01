import 'package:get_it/get_it.dart';
import '../services/gps_tracking_service.dart';
import '../../features/ride_calculator/presentation/controllers/ride_signal_controller.dart';

/// Instância global do Service Locator [GetIt].
final GetIt getIt = GetIt.instance;

/// Inicializa e registra todas as dependências e controllers do projeto.
///
/// Esta função deve ser invocada na inicialização do aplicativo (`main.dart`).
void setupServiceLocator() {
  // 1. Registra o RideSignalController
  if (!getIt.isRegistered<RideSignalController>()) {
    getIt.registerLazySingleton<RideSignalController>(
      () => RideSignalController(),
      dispose: (controller) => controller.dispose(),
    );
  }

  // 2. Registra o GpsTrackingService (Serviço de GPS)
  if (!getIt.isRegistered<GpsTrackingService>()) {
    getIt.registerLazySingleton<GpsTrackingService>(
      () => GpsTrackingService(getIt<RideSignalController>()),
      dispose: (service) => service.dispose(),
    );
  }
}
