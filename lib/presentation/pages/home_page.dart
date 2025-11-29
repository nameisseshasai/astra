import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/utils/danger_detector.dart';
import '../../domain/entities/app_state.dart';
import '../bloc/astra_bloc.dart';
import '../bloc/astra_event.dart';
import '../bloc/astra_state.dart';
import '../theme/app_theme.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/control_panel_widget.dart';
import '../widgets/danger_indicator_widget.dart';
import '../widgets/loading_overlay_widget.dart';
import '../widgets/scene_description_widget.dart';
import 'settings_page.dart';

/// Main home page of the Astra accessibility app
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AstraBloc, AstraState>(
      listener: (context, state) {
        // Show error snackbar
        if (state.status == AppStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AstraTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        // Show loading overlay for initialization states
        if (_shouldShowLoadingOverlay(state.status)) {
          return Scaffold(
            body: LoadingOverlayWidget(
              status: state.status,
              downloadProgress: state.downloadProgress,
              errorMessage: state.errorMessage,
              onRetry: () =>
                  context.read<AstraBloc>().add(const InitializeApp()),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(child: _buildMainContent(context, state)),
        );
      },
    );
  }

  bool _shouldShowLoadingOverlay(AppStatus status) {
    return status == AppStatus.initial ||
        status == AppStatus.loading ||
        status == AppStatus.modelDownloading ||
        status == AppStatus.modelInitializing ||
        status == AppStatus.error;
  }

  Widget _buildMainContent(BuildContext context, AstraState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AstraTheme.backgroundColor, Color(0xFF0A0F1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  // decoration: BoxDecoration(
                  //   gradient: const LinearGradient(
                  //     colors: [
                  //       AstraTheme.primaryColor,
                  //       AstraTheme.secondaryColor,
                  //     ],
                  //   ),
                  //   borderRadius: BorderRadius.circular(12),
                  // ),
                  child: Image.asset('assets/icons/ic_launcher.png', width: 40, height: 40),
                  
                  
                  // const Icon(
                  //   Icons.visibility,
                  //   color: Colors.white,
                  //   size: 24,
                  // ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ASTRA',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: AstraTheme.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _openSettings(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Main content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Camera preview
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: CameraPreviewWidget(
                    controller: state.cameraController,
                    isAnalyzing: state.isAnalyzing,
                    hasDanger: state.hasDanger,
                    dangerLevel: state.currentAnalysis != null
                        ? DangerDetector.getDangerPriority(
                            state.currentAnalysis!.dangerInfo.level,
                          )
                        : 0,
                  ),
                ),
                const SizedBox(height: 20),

                // Danger indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: state.currentAnalysis != null
                      ? DangerIndicatorWidget(
                          key: ValueKey(
                            state.currentAnalysis!.dangerInfo.level,
                          ),
                          dangerInfo: state.currentAnalysis!.dangerInfo,
                          animate: state.isAnalyzing,
                        )
                      : DangerIndicatorWidget(
                          dangerInfo: DangerInfo.safe(),
                          animate: false,
                        ),
                ),
                const SizedBox(height: 20),

                // Scene description with streaming support
                SceneDescriptionWidget(
                  analysis: state.currentAnalysis,
                  isAnalyzing: state.isAnalyzing,
                  isStreaming: state.isStreaming,
                  streamingText: state.streamingText,
                  isProcessingFrame: state.isProcessingFrame,
                ),
                const SizedBox(height: 20),

                // Control panel
                ControlPanelWidget(
                  isAnalyzing: state.isAnalyzing,
                  settings: state.settings,
                  onStartStop: () {
                    if (state.isAnalyzing) {
                      context.read<AstraBloc>().add(const StopAnalysis());
                    } else {
                      context.read<AstraBloc>().add(const StartAnalysis());
                    }
                  },
                  onToggleVoice: () {
                    context.read<AstraBloc>().add(const ToggleVoiceFeedback());
                  },
                  onToggleHaptic: () {
                    context.read<AstraBloc>().add(const ToggleHapticFeedback());
                  },
                  onToggleDanger: () {
                    context.read<AstraBloc>().add(const ToggleDangerAlerts());
                  },
                  onOpenSettings: () => _openSettings(context),
                ),
                const SizedBox(height: 32),

                // Status bar
                _buildStatusBar(state),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(AstraState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AstraTheme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            icon: Icons.camera_alt,
            label: 'Camera',
            isActive: state.isCameraReady,
          ),
          _buildStatusItem(
            icon: Icons.psychology,
            label: 'Model',
            isActive:
                state.status == AppStatus.ready ||
                state.status == AppStatus.analyzing,
          ),
          _buildStatusItem(
            icon: Icons.analytics,
            label: 'Analyses',
            value: state.analysisCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    bool? isActive,
    String? value,
  }) {
    final color = isActive == true
        ? AstraTheme.safeColor
        : (isActive == false
              ? AstraTheme.textSecondary
              : AstraTheme.primaryColor);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value ?? label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
  }
}
