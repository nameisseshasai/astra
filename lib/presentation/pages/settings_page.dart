import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_state.dart';
import '../bloc/astra_bloc.dart';
import '../bloc/astra_event.dart';
import '../bloc/astra_state.dart';
import '../theme/app_theme.dart';

/// Settings page for accessibility configuration
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AstraBloc, AstraState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AstraTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            // leadingWidth: 10,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Feedback Options'),
                const SizedBox(height: 16),
                _buildSettingsCard([
                  _buildSwitchTile(
                    icon: Icons.record_voice_over,
                    title: 'Voice Feedback',
                    subtitle: 'Speak scene descriptions aloud',
                    value: state.settings.enableVoiceFeedback,
                    onChanged: (_) {
                      context.read<AstraBloc>().add(
                        const ToggleVoiceFeedback(),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Morse code vibrations for objects',
                    value: state.settings.enableHapticFeedback,
                    onChanged: (_) {
                      context.read<AstraBloc>().add(
                        const ToggleHapticFeedback(),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.warning_amber,
                    title: 'Danger Alerts',
                    subtitle: 'Priority alerts for hazardous situations',
                    value: state.settings.enableDangerAlerts,
                    onChanged: (_) {
                      context.read<AstraBloc>().add(const ToggleDangerAlerts());
                    },
                  ),
                ]),

                const SizedBox(height: 32),
                _buildSectionTitle('Voice Settings'),
                const SizedBox(height: 16),
                _buildSettingsCard([
                  _buildSliderTile(
                    icon: Icons.speed,
                    title: 'Speech Rate',
                    value: state.settings.speechRate,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (value) {
                      _updateSettings(
                        context,
                        state.settings.copyWith(speechRate: value),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildSliderTile(
                    icon: Icons.tune,
                    title: 'Speech Pitch',
                    value: state.settings.speechPitch,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (value) {
                      _updateSettings(
                        context,
                        state.settings.copyWith(speechPitch: value),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 32),
                _buildSectionTitle('Analysis Settings'),
                const SizedBox(height: 16),
                _buildSettingsCard([
                  _buildSliderTile(
                    icon: Icons.timer,
                    title: 'Analysis Interval',
                    subtitle:
                        '${state.settings.analysisIntervalSeconds} seconds',
                    value: state.settings.analysisIntervalSeconds.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) {
                      _updateSettings(
                        context,
                        state.settings.copyWith(
                          analysisIntervalSeconds: value.toInt(),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 32),
                _buildSectionTitle('Morse Code Reference'),
                const SizedBox(height: 16),
                _buildMorseCodeReference(),

                const SizedBox(height: 32),
                _buildSectionTitle('About'),
                const SizedBox(height: 16),
                _buildAboutCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateSettings(BuildContext context, AccessibilitySettings settings) {
    context.read<AstraBloc>().add(UpdateSettings(settings));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AstraTheme.primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AstraTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AstraTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AstraTheme.backgroundColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AstraTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AstraTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AstraTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AstraTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AstraTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AstraTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AstraTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AstraTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AstraTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMorseCodeReference() {
    final patterns = [
      ('Safe', '...', AstraTheme.safeColor),
      ('Person', '.--.', AstraTheme.primaryColor),
      ('Road', '.-.', AstraTheme.warningColor),
      ('Water', '.--', AstraTheme.primaryColor),
      ('Vehicle', '-...-', AstraTheme.dangerColor),
      ('Obstacle', '---', AstraTheme.warningColor),
      ('Danger', '---...---', AstraTheme.dangerColor),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AstraTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AstraTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AstraTheme.primaryColor),
              SizedBox(width: 12),
              Text(
                'Vibration Patterns',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AstraTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...patterns.map((p) => _buildMorseRow(p.$1, p.$2, p.$3)),
        ],
      ),
    );
  }

  Widget _buildMorseRow(String label, String pattern, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: pattern.split('').map((char) {
              if (char == '.') {
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                );
              } else if (char == '-') {
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 20,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }
              return const SizedBox(width: 8);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: AstraTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AstraTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AstraTheme.primaryColor,
                      AstraTheme.secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ASTRA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AstraTheme.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 13,
                      color: AstraTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Accessibility Vision Assistant for DeafBlind individuals. '
            'Uses local AI vision model to analyze scenes and provide '
            'voice and haptic feedback.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AstraTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.memory, size: 16, color: AstraTheme.textSecondary),
              SizedBox(width: 8),
             Expanded(child:
              Text(
                'Powered by Cactus SDK & Developed by seshasai - nvsseshasai@gmail.com',
                style: TextStyle(fontSize: 12, color: AstraTheme.textSecondary),
              ),)
            ],
          ),
        ],
      ),
    );
  }
}

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
