import '../constants/app_constants.dart';

/// Enum representing different danger levels
enum DangerLevel { safe, caution, warning, danger, critical }

/// Represents a detected danger with its type and level
class DangerInfo {
  final DangerType type;
  final DangerLevel level;
  final String description;
  final String morsePattern;

  const DangerInfo({
    required this.type,
    required this.level,
    required this.description,
    required this.morsePattern,
  });

  factory DangerInfo.safe() => const DangerInfo(
    type: DangerType.none,
    level: DangerLevel.safe,
    description: 'Area appears safe',
    morsePattern: MorseCode.safe,
  );
}

/// Types of dangers that can be detected
enum DangerType { none, vehicle, water, road, obstacle, general }

/// Utility class to detect dangers from scene analysis text
/// UPDATED: Smarter vehicle detection - only MOVING vehicles are danger
class DangerDetector {
  DangerDetector._();

  /// Safe context indicators - if present, reduce danger level
  static const List<String> _safeIndicators = [
    'parked',
    'stationary',
    'stopped',
    'empty',
    'indoor',
    'inside',
    'room',
    'safe',
    'clear',
    'no obstacle',
    'path clear',
    'safe to',
    'can walk',
    'can move',
    'freely',
  ];

  /// Moving vehicle indicators - ONLY these trigger vehicle danger
  static const List<String> _movingVehicleIndicators = [
    'moving car',
    'moving vehicle',
    'approaching',
    'coming toward',
    'speeding',
    'driving toward',
    'oncoming',
    'car ahead',
    'vehicle ahead',
    'crossing traffic',
    'active traffic',
    'fast',
    'approaching fast',
    'watch out',
    'stop now',
    'stop immediately',
  ];

  /// Danger status indicators from prompt response
  static const List<String> _dangerStatusIndicators = [
    'danger!',
    'danger:',
    'warning!',
    'warning:',
    'caution!',
    'caution:',
  ];

  /// Safe status indicators from prompt response
  static const List<String> _safeStatusIndicators = [
    'safe:',
    'safe.',
    'area safe',
    'path clear',
    'move freely',
    'walk forward',
    'safe to move',
    'safe to walk',
  ];

  /// Analyzes the scene description and returns danger information
  /// SMART: Checks context before flagging danger
  static DangerInfo analyzeScene(String sceneDescription) {
    final lowerDesc = sceneDescription.toLowerCase();

    // FIRST: Check if response explicitly says SAFE
    if (_containsKeywords(lowerDesc, _safeStatusIndicators)) {
      return DangerInfo.safe();
    }

    // Check for explicit DANGER status from LLM response
    if (_containsKeywords(lowerDesc, _dangerStatusIndicators)) {
      // Determine what type of danger
      if (_containsMovingVehicle(lowerDesc)) {
        return const DangerInfo(
          type: DangerType.vehicle,
          level: DangerLevel.critical,
          description: 'Moving vehicle! Stop immediately.',
          morsePattern: MorseCode.danger,
        );
      }
      if (_containsKeywords(lowerDesc, DangerKeywords.waterKeywords)) {
        return const DangerInfo(
          type: DangerType.water,
          level: DangerLevel.danger,
          description: 'Water hazard nearby!',
          morsePattern: MorseCode.water,
        );
      }
      if (_containsKeywords(lowerDesc, ['stair', 'step', 'drop', 'edge'])) {
        return const DangerInfo(
          type: DangerType.obstacle,
          level: DangerLevel.warning,
          description: 'Stairs or drop ahead',
          morsePattern: MorseCode.obstacle,
        );
      }
      // Generic danger
      return const DangerInfo(
        type: DangerType.general,
        level: DangerLevel.danger,
        description: 'Hazard detected',
        morsePattern: MorseCode.danger,
      );
    }

    // Check for MOVING vehicles (not just any vehicle mention)
    if (_containsMovingVehicle(lowerDesc)) {
      return const DangerInfo(
        type: DangerType.vehicle,
        level: DangerLevel.critical,
        description: 'Moving vehicle detected!',
        morsePattern: MorseCode.danger,
      );
    }

    // If safe context present with vehicle mention = SAFE (parked car)
    if (_containsSafeContext(lowerDesc)) {
      // Even if vehicle mentioned, it's parked/safe
      return DangerInfo.safe();
    }

    // Check for water bodies (always warning)
    if (_containsKeywords(lowerDesc, DangerKeywords.waterKeywords)) {
      return const DangerInfo(
        type: DangerType.water,
        level: DangerLevel.warning,
        description: 'Water nearby',
        morsePattern: MorseCode.water,
      );
    }

    // Check for active road/crossing (not just road mention)
    if (_containsActiveRoad(lowerDesc)) {
      return const DangerInfo(
        type: DangerType.road,
        level: DangerLevel.warning,
        description: 'Road crossing area',
        morsePattern: MorseCode.road,
      );
    }

    // Check for obstacles in path
    if (_containsPathObstacle(lowerDesc)) {
      return const DangerInfo(
        type: DangerType.obstacle,
        level: DangerLevel.caution,
        description: 'Obstacle in path',
        morsePattern: MorseCode.obstacle,
      );
    }

    // Default: Safe
    return DangerInfo.safe();
  }

  /// Check if text indicates MOVING vehicle (not parked)
  static bool _containsMovingVehicle(String text) {
    // If parked/stationary mentioned with vehicle, it's safe
    if (_containsKeywords(text, ['parked', 'stationary', 'stopped'])) {
      return false;
    }
    return _containsKeywords(text, _movingVehicleIndicators);
  }

  /// Check if safe context is present
  static bool _containsSafeContext(String text) {
    return _containsKeywords(text, _safeIndicators);
  }

  /// Check for active road crossing (not just road mention)
  static bool _containsActiveRoad(String text) {
    final activeRoadIndicators = [
      'crossing',
      'cross the road',
      'traffic',
      'intersection',
      'busy road',
      'active road',
    ];
    // If sidewalk mentioned, likely safe
    if (text.contains('sidewalk') && !text.contains('cross')) {
      return false;
    }
    return _containsKeywords(text, activeRoadIndicators);
  }

  /// Check for obstacles actually in path
  static bool _containsPathObstacle(String text) {
    final pathObstacles = [
      'stair',
      'step',
      'hole',
      'pit',
      'construction',
      'barrier ahead',
      'obstacle ahead',
      'blocked',
      'edge',
      'drop',
      'cliff',
    ];
    return _containsKeywords(text, pathObstacles);
  }

  /// Check if text contains any of the keywords
  static bool _containsKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Get priority level for danger (higher = more urgent)
  static int getDangerPriority(DangerLevel level) {
    return switch (level) {
      DangerLevel.safe => 0,
      DangerLevel.caution => 1,
      DangerLevel.warning => 2,
      DangerLevel.danger => 3,
      DangerLevel.critical => 4,
    };
  }
}
