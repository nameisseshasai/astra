import 'package:get_it/get_it.dart';

import '../data/repositories/camera_repository_impl.dart';
import '../data/repositories/feedback_repository_impl.dart';
import '../data/repositories/vision_repository_impl.dart';
import '../data/services/camera_service.dart';
import '../data/services/feedback_service.dart';
import '../data/services/tool_executor_service.dart';
import '../data/services/vision_service.dart';
import '../domain/repositories/camera_repository.dart';
import '../domain/repositories/feedback_repository.dart';
import '../domain/repositories/vision_repository.dart';
import '../domain/usecases/analyze_scene_usecase.dart';
import '../domain/usecases/provide_feedback_usecase.dart';
import '../presentation/bloc/astra_bloc.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // Services (Singletons)
  sl.registerLazySingleton<VisionService>(() => VisionService());
  sl.registerLazySingleton<FeedbackService>(() => FeedbackService());
  sl.registerLazySingleton<CameraService>(() => CameraService());

  // Tool Executor Service (depends on FeedbackService)
  sl.registerLazySingleton<ToolExecutorService>(
    () => ToolExecutorService(sl<FeedbackService>()),
  );

  // Repositories
  sl.registerLazySingleton<VisionRepository>(
    () => VisionRepositoryImpl(sl<VisionService>(), sl<ToolExecutorService>()),
  );
  sl.registerLazySingleton<FeedbackRepository>(
    () => FeedbackRepositoryImpl(sl<FeedbackService>()),
  );
  sl.registerLazySingleton<CameraRepository>(
    () => CameraRepositoryImpl(sl<CameraService>()),
  );

  // Use Cases
  sl.registerLazySingleton<AnalyzeSceneUseCase>(
    () => AnalyzeSceneUseCase(sl<VisionRepository>()),
  );
  sl.registerLazySingleton<ProvideFeedbackUseCase>(
    () => ProvideFeedbackUseCase(sl<FeedbackRepository>()),
  );

  // BLoC (Factory - new instance each time)
  sl.registerFactory<AstraBloc>(
    () => AstraBloc(
      visionRepository: sl<VisionRepository>(),
      cameraRepository: sl<CameraRepository>(),
      feedbackRepository: sl<FeedbackRepository>(),
      analyzeSceneUseCase: sl<AnalyzeSceneUseCase>(),
      provideFeedbackUseCase: sl<ProvideFeedbackUseCase>(),
    ),
  );
}

/// Reset all dependencies (for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}
