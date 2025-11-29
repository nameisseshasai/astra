import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/danger_detector.dart';
import '../../domain/entities/app_state.dart';
import 'feedback_service.dart';
import 'tool_definitions.dart';
import 'vision_service.dart';

/// Service to execute tool calls from AI model
/// ALWAYS provides TTS feedback for DeafBlind users
class ToolExecutorService {
  final FeedbackService _feedbackService;

  // Settings for feedback control
  AccessibilitySettings _settings = const AccessibilitySettings();

  ToolExecutorService(this._feedbackService);

  /// Update settings for feedback control
  void updateSettings(AccessibilitySettings settings) {
    _settings = settings;
  }

  /// Execute all tool calls from a vision analysis result
  /// ALWAYS speaks the response for DeafBlind users
  Future<ExecutionResult> executeToolCalls(VisionAnalysisResult result) async {
    debugPrint('=== Executing Tool Calls ===');
    debugPrint('Response: ${result.response}');
    debugPrint('Tool calls: ${result.toolCalls.length}');
    debugPrint('Voice enabled: ${_settings.enableVoiceFeedback}');
    debugPrint('Haptic enabled: ${_settings.enableHapticFeedback}');
    
    final executedTools = <String>[];
    DangerInfo? detectedDanger;
    String? spokenText;
    String? sceneDescription;
    bool ttsExecuted = false;

    // Process tool calls if any
    if (result.toolCalls.isNotEmpty) {
      for (final toolCall in result.toolCalls) {
        debugPrint('Processing tool: ${toolCall.name}');
        final parsed = VisionAnalysisResult.parseToolCall(toolCall);

        switch (toolCall.name) {
          case 'detect_danger':
            detectedDanger = await _executeDetectDanger(parsed);
            executedTools.add('detect_danger');
            break;

          case 'alert_danger':
            detectedDanger = await _executeAlertDanger(parsed);
            executedTools.add('alert_danger');
            ttsExecuted = true; // alert_danger speaks
            break;

          case 'vibrate_morse':
            await _executeVibrateMorse(parsed);
            executedTools.add('vibrate_morse');
            break;

          case 'speak_text':
            spokenText = await _executeSpeakText(parsed);
            executedTools.add('speak_text');
            ttsExecuted = true;
            break;

          case 'describe_scene':
            sceneDescription = await _executeDescribeScene(parsed);
            executedTools.add('describe_scene');
            ttsExecuted = true; // describe_scene speaks
            break;
        }
      }
    }

    // Get danger info
    detectedDanger ??= result.effectiveDangerInfo;

    // ALWAYS SPEAK if TTS wasn't already executed
    if (!ttsExecuted) {
      debugPrint('TTS not executed by tools, using fallback');
      await _provideFeedbackFromResponse(result, detectedDanger);
      executedTools.add('fallback_tts');
    }

    debugPrint('Executed tools: $executedTools');

    return ExecutionResult(
      executedTools: executedTools,
      dangerInfo: detectedDanger,
      spokenText: spokenText ?? result.response,
      sceneDescription: sceneDescription ?? result.response,
      rawResponse: result.response,
      detectedObjects: result.detectedObjects,
    );
  }

  /// Provide feedback - ALWAYS speaks for DeafBlind users
  Future<void> _provideFeedbackFromResponse(
    VisionAnalysisResult result,
    DangerInfo dangerInfo,
  ) async {
    debugPrint('=== Providing Feedback ===');
    debugPrint('Response to speak: "${result.response}"');
    debugPrint('Danger level: ${dangerInfo.level}');
    
    // STEP 1: HAPTIC FEEDBACK
    if (_settings.enableHapticFeedback) {
      debugPrint('Haptic feedback enabled');
      try {
        final bool isDanger = dangerInfo.level == DangerLevel.critical ||
            dangerInfo.level == DangerLevel.danger ||
            dangerInfo.level == DangerLevel.warning;

        if (_settings.enableDangerAlerts && isDanger) {
          debugPrint('Vibrating danger alert: ${dangerInfo.level}');
          await _feedbackService.vibrateDangerAlert(dangerInfo.level);
        } else {
          debugPrint('Vibrating safe confirmation');
          await _feedbackService.vibrateSafeConfirmation();
        }
      } catch (e) {
        debugPrint('Haptic error: $e');
      }
    }

    // STEP 2: TTS - ALWAYS SPEAK
    debugPrint('TTS enabled: ${_settings.enableVoiceFeedback}');
    debugPrint('TTS initialized: ${_feedbackService.isInitialized}');
    
    if (_settings.enableVoiceFeedback) {
      String textToSpeak = result.response.trim();

      // Provide default if empty
      if (textToSpeak.isEmpty) {
        textToSpeak = dangerInfo.level == DangerLevel.safe
            ? 'Area appears safe.'
            : 'Caution advised.';
        debugPrint('Using default text: $textToSpeak');
      }

      // Limit length
      if (textToSpeak.length > 150) {
        textToSpeak = '${textToSpeak.substring(0, 147)}...';
      }

      debugPrint('Speaking: "$textToSpeak"');
      try {
        await _feedbackService.speak(textToSpeak);
        debugPrint('TTS speak called successfully');
      } catch (e) {
        debugPrint('TTS error: $e');
      }
    } else {
      debugPrint('TTS disabled in settings');
    }
  }

  /// Execute detect_danger tool
  Future<DangerInfo> _executeDetectDanger(ToolCallResult parsed) async {
    final dangerType = _parseDangerType(parsed.dangerType ?? 'general');
    final dangerLevel = _parseDangerLevel(parsed.dangerLevel ?? 'caution');
    final description = parsed.description ?? 'Potential danger detected';
    final morsePattern = _getMorsePatternForDanger(dangerType);

    // Vibrate danger pattern (if enabled and danger alerts are on)
    if (_settings.enableHapticFeedback && _settings.enableDangerAlerts) {
      await _feedbackService.vibrateDangerAlert(dangerLevel);
    }

    return DangerInfo(
      type: dangerType,
      level: dangerLevel,
      description: description,
      morsePattern: morsePattern,
    );
  }

  /// Execute alert_danger tool (immediate danger alert)
  Future<DangerInfo> _executeAlertDanger(ToolCallResult parsed) async {
    final alertType = parsed.alertType ?? 'general_danger';
    final message = parsed.message ?? 'Danger nearby!';

    // Determine danger type and level from alert type
    final dangerType = _parseDangerTypeFromAlert(alertType);
    const dangerLevel = DangerLevel.critical;

    // Immediate vibration alert (if enabled)
    if (_settings.enableHapticFeedback && _settings.enableDangerAlerts) {
      await _feedbackService.vibrateDangerAlert(dangerLevel);
    }

    // Speak the warning (if enabled)
    if (_settings.enableVoiceFeedback && _settings.enableDangerAlerts) {
      await _feedbackService.speak('Warning! $message');
    }

    return DangerInfo(
      type: dangerType,
      level: dangerLevel,
      description: message,
      morsePattern: MorseCode.danger,
    );
  }

  /// Execute vibrate_morse tool
  Future<void> _executeVibrateMorse(ToolCallResult parsed) async {
    if (!_settings.enableHapticFeedback) return;

    final objectType = parsed.objectType ?? 'safe';
    final morsePattern = _getMorsePatternForObject(objectType);

    await _feedbackService.vibrateMorseCode(morsePattern);
  }

  /// Execute speak_text tool
  Future<String> _executeSpeakText(ToolCallResult parsed) async {
    final text = parsed.text ?? '';
    if (text.isNotEmpty && _settings.enableVoiceFeedback) {
      await _feedbackService.speak(text);
    }
    return text;
  }

  /// Execute describe_scene tool
  Future<String> _executeDescribeScene(ToolCallResult parsed) async {
    final description = parsed.description ?? 'Unable to describe scene';
    final environment = parsed.environment ?? 'unknown';

    // Provide a short vibration to indicate scene description (if enabled)
    if (_settings.enableHapticFeedback) {
      await _feedbackService.vibrateShort();
    }

    // Speak the description (if enabled)
    if (_settings.enableVoiceFeedback) {
      await _feedbackService.speak('$environment environment. $description');
    }

    return '$environment: $description';
  }

  /// Parse danger type from string
  DangerType _parseDangerType(String type) {
    return switch (type.toLowerCase()) {
      'vehicle' || 'car' || 'truck' || 'bus' => DangerType.vehicle,
      'water' || 'pool' || 'river' || 'lake' => DangerType.water,
      'road' || 'street' || 'traffic' || 'crossing' => DangerType.road,
      'obstacle' || 'barrier' || 'stairs' || 'steps' => DangerType.obstacle,
      _ => DangerType.general,
    };
  }

  /// Parse danger level from string
  DangerLevel _parseDangerLevel(String level) {
    return switch (level.toLowerCase()) {
      'critical' => DangerLevel.critical,
      'danger' || 'high' => DangerLevel.danger,
      'warning' || 'medium' => DangerLevel.warning,
      'caution' || 'low' => DangerLevel.caution,
      'safe' || 'none' => DangerLevel.safe,
      _ => DangerLevel.caution,
    };
  }

  /// Parse danger type from alert type
  DangerType _parseDangerTypeFromAlert(String alertType) {
    return switch (alertType.toLowerCase()) {
      'moving_vehicle' || 'approaching_vehicle' => DangerType.vehicle,
      'water_nearby' || 'water_body' => DangerType.water,
      'road_crossing' || 'traffic' => DangerType.road,
      'obstacle_ahead' || 'barrier' => DangerType.obstacle,
      _ => DangerType.general,
    };
  }

  /// Get morse pattern for danger type
  String _getMorsePatternForDanger(DangerType type) {
    return switch (type) {
      DangerType.vehicle => MorseCode.vehicle,
      DangerType.water => MorseCode.water,
      DangerType.road => MorseCode.road,
      DangerType.obstacle => MorseCode.obstacle,
      DangerType.general => MorseCode.danger,
      DangerType.none => MorseCode.safe,
    };
  }

  /// Get morse pattern for object type
  String _getMorsePatternForObject(String objectType) {
    return switch (objectType.toLowerCase()) {
      'person' || 'people' => MorseCode.person,
      'vehicle' || 'car' || 'truck' => MorseCode.vehicle,
      'water' || 'pool' || 'river' => MorseCode.water,
      'road' || 'street' => MorseCode.road,
      'obstacle' || 'barrier' || 'wall' => MorseCode.obstacle,
      'safe' || 'clear' => MorseCode.safe,
      _ => MorseCode.safe,
    };
  }
}

/// Result of executing tool calls
class ExecutionResult {
  final List<String> executedTools;
  final DangerInfo dangerInfo;
  final String? spokenText;
  final String sceneDescription;
  final String rawResponse;
  final List<String> detectedObjects;

  const ExecutionResult({
    required this.executedTools,
    required this.dangerInfo,
    required this.spokenText,
    required this.sceneDescription,
    required this.rawResponse,
    this.detectedObjects = const [],
  });

  /// Check if any tools were executed
  bool get hasToolsExecuted => executedTools.isNotEmpty;

  /// Check if danger was detected
  bool get hasDanger =>
      dangerInfo.level != DangerLevel.safe &&
      dangerInfo.level != DangerLevel.caution;

  /// Get the final description to display
  String get displayDescription =>
      sceneDescription.isNotEmpty ? sceneDescription : rawResponse;
}
