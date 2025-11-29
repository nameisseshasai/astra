import 'package:cactus/cactus.dart';

/// Simple tool definitions for fast tool calling
class AstraTools {
  AstraTools._();

  /// Report danger
  static final CactusTool detectDanger = CactusTool(
    name: 'detect_danger',
    description: 'Report hazard',
    parameters: ToolParametersSchema(
      properties: {
        'danger_type': ToolParameter(
          type: 'string',
          description: 'vehicle/water/road/obstacle/stairs',
          required: true,
        ),
        'danger_level': ToolParameter(
          type: 'string',
          description: 'critical/danger/warning/caution',
          required: true,
        ),
        'description': ToolParameter(
          type: 'string',
          description: 'Short danger description',
          required: true,
        ),
      },
    ),
  );

  /// Vibrate morse
  static final CactusTool vibrateMorseCode = CactusTool(
    name: 'vibrate_morse',
    description: 'Vibrate for object',
    parameters: ToolParametersSchema(
      properties: {
        'object_type': ToolParameter(
          type: 'string',
          description: 'person/vehicle/water/road/obstacle/safe',
          required: true,
        ),
      },
    ),
  );

  /// Speak message
  static final CactusTool speakText = CactusTool(
    name: 'speak_text',
    description: 'Speak guidance',
    parameters: ToolParametersSchema(
      properties: {
        'text': ToolParameter(
          type: 'string',
          description: 'Short message to speak',
          required: true,
        ),
      },
    ),
  );

  /// Urgent alert
  static final CactusTool alertDanger = CactusTool(
    name: 'alert_danger',
    description: 'Urgent danger',
    parameters: ToolParametersSchema(
      properties: {
        'alert_type': ToolParameter(
          type: 'string',
          description: 'moving_vehicle/water/road/obstacle',
          required: true,
        ),
        'message': ToolParameter(
          type: 'string',
          description: 'Short warning',
          required: true,
        ),
      },
    ),
  );

  /// Describe scene
  static final CactusTool describeScene = CactusTool(
    name: 'describe_scene',
    description: 'Describe environment',
    parameters: ToolParametersSchema(
      properties: {
        'environment': ToolParameter(
          type: 'string',
          description: 'indoor/outdoor/street/park',
          required: true,
        ),
        'description': ToolParameter(
          type: 'string',
          description: 'Short description',
          required: true,
        ),
      },
    ),
  );

  /// Get all tools as a list
  static List<CactusTool> get allTools => [
    detectDanger,
    vibrateMorseCode,
    speakText,
    alertDanger,
    describeScene,
  ];

  /// Get only danger-related tools for faster processing
  static List<CactusTool> get dangerTools => [detectDanger, alertDanger];

  /// Get feedback tools
  static List<CactusTool> get feedbackTools => [
    vibrateMorseCode,
    speakText,
    describeScene,
  ];
}

/// Parsed result from tool calls
class ToolCallResult {
  final String toolName;
  final Map<String, String> arguments;

  const ToolCallResult({required this.toolName, required this.arguments});

  /// Parse danger type from arguments
  String? get dangerType => arguments['danger_type'];

  /// Parse danger level from arguments
  String? get dangerLevel => arguments['danger_level'];

  /// Parse description from arguments
  String? get description => arguments['description'];

  /// Parse object type from arguments
  String? get objectType => arguments['object_type'];

  /// Parse text from arguments
  String? get text => arguments['text'];

  /// Parse alert type from arguments
  String? get alertType => arguments['alert_type'];

  /// Parse message from arguments
  String? get message => arguments['message'];

  /// Parse environment from arguments
  String? get environment => arguments['environment'];

  @override
  String toString() => 'ToolCallResult(toolName: $toolName, args: $arguments)';
}
