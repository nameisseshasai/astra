import 'package:flutter/material.dart';

import '../../domain/entities/app_state.dart';
import '../theme/app_theme.dart';

/// Widget containing the main control buttons and toggles
class ControlPanelWidget extends StatelessWidget {
  final bool isAnalyzing;
  final AccessibilitySettings settings;
  final VoidCallback onStartStop;
  final VoidCallback onToggleVoice;
  final VoidCallback onToggleHaptic;
  final VoidCallback onToggleDanger;
  final VoidCallback? onOpenSettings;

  const ControlPanelWidget({
    super.key,
    required this.isAnalyzing,
    required this.settings,
    required this.onStartStop,
    required this.onToggleVoice,
    required this.onToggleHaptic,
    required this.onToggleDanger,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AstraTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AstraTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main action button
          _buildMainButton(),
          const SizedBox(height: 24),
          // Quick toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToggleButton(
                icon: settings.enableVoiceFeedback
                    ? Icons.volume_up
                    : Icons.volume_off,
                label: 'Voice',
                isActive: settings.enableVoiceFeedback,
                onTap: onToggleVoice,
              ),
              _buildToggleButton(
                icon: settings.enableHapticFeedback
                    ? Icons.vibration
                    : Icons.smartphone,
                label: 'Haptic',
                isActive: settings.enableHapticFeedback,
                onTap: onToggleHaptic,
              ),
              _buildToggleButton(
                icon: settings.enableDangerAlerts
                    ? Icons.warning
                    : Icons.warning_amber_outlined,
                label: 'Alerts',
                isActive: settings.enableDangerAlerts,
                onTap: onToggleDanger,
              ),
              if (onOpenSettings != null)
                _buildToggleButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  isActive: false,
                  onTap: onOpenSettings!,
                  showActiveState: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: onStartStop,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAnalyzing
                ? [
                    AstraTheme.dangerColor,
                    AstraTheme.dangerColor.withValues(alpha: 0.8),
                  ]
                : [AstraTheme.primaryColor, AstraTheme.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  (isAnalyzing
                          ? AstraTheme.dangerColor
                          : AstraTheme.primaryColor)
                      .withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAnalyzing ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(width: 12),
            Text(
              isAnalyzing ? 'STOP ANALYSIS' : 'START ANALYSIS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool showActiveState = true,
  }) {
    final color = showActiveState && isActive
        ? AstraTheme.primaryColor
        : AstraTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: showActiveState && isActive
                  ? AstraTheme.primaryColor.withValues(alpha: 0.2)
                  : AstraTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
