import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'di/injection.dart';
import 'presentation/bloc/astra_bloc.dart';
import 'presentation/bloc/astra_event.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AstraTheme.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize dependencies
  await initDependencies();

  // Request permissions
  await _requestPermissions();

  runApp(const AstraApp());
}

/// Request necessary permissions
Future<void> _requestPermissions() async {
  await [Permission.camera, Permission.microphone].request();
}

/// Main application widget
class AstraApp extends StatelessWidget {
  const AstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AstraBloc>()..add(const InitializeApp()),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Astra - Vision Assistant',
        debugShowCheckedModeBanner: false,
        theme: AstraTheme.darkTheme(),
        home: const HomePage(),
      ),
    );
  }
}
