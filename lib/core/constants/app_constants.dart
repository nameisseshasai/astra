/// Application-wide constants for Astra accessibility app
library;

/// Morse code patterns for common objects and danger alerts
/// Each character: '.' = short vibration, '-' = long vibration
class MorseCode {
  MorseCode._();

  // Duration constants (in milliseconds)
  static const int dotDuration = 100;
  static const int dashDuration = 300;
  static const int symbolGap = 100;
  static const int letterGap = 300;
  static const int wordGap = 700;

  // Danger alert patterns (custom patterns for quick recognition)
  static const String danger = '---...---'; // SOS reversed for danger
  static const String vehicle = '-...-'; // V in morse
  static const String water = '.--'; // W in morse
  static const String road = '.-.'; // R in morse
  static const String obstacle = '---'; // O in morse
  static const String person = '.--.'; // P in morse
  static const String safe = '...'; // S in morse

  // Standard morse code alphabet
  static const Map<String, String> alphabet = {
    'A': '.-',
    'B': '-...',
    'C': '-.-.',
    'D': '-..',
    'E': '.',
    'F': '..-.',
    'G': '--.',
    'H': '....',
    'I': '..',
    'J': '.---',
    'K': '-.-',
    'L': '.-..',
    'M': '--',
    'N': '-.',
    'O': '---',
    'P': '.--.',
    'Q': '--.-',
    'R': '.-.',
    'S': '...',
    'T': '-',
    'U': '..-',
    'V': '...-',
    'W': '.--',
    'X': '-..-',
    'Y': '-.--',
    'Z': '--..',
    '0': '-----',
    '1': '.----',
    '2': '..---',
    '3': '...--',
    '4': '....-',
    '5': '.....',
    '6': '-....',
    '7': '--...',
    '8': '---..',
    '9': '----.',
    ' ': ' ',
  };
}

/// Danger categories and their associated keywords
/// NOTE: Vehicle detection now requires MOTION context
class DangerKeywords {
  DangerKeywords._();

  /// MOVING vehicle keywords - only these trigger vehicle danger
  /// Parked/stationary cars are NOT included
  static const List<String> vehicleKeywords = [
    'moving car',
    'moving vehicle',
    'approaching vehicle',
    'approaching car',
    'oncoming traffic',
    'speeding',
    'driving toward',
    'car approaching',
    'vehicle approaching',
    'active traffic',
  ];

  /// Water hazard keywords
  static const List<String> waterKeywords = [
    'water body',
    'pool',
    'river',
    'lake',
    'pond',
    'ocean',
    'sea',
    'flood',
    'stream',
    'deep water',
    'swimming',
  ];

  /// Active road crossing keywords (not just road mention)
  static const List<String> roadKeywords = [
    'cross the road',
    'road crossing',
    'crosswalk',
    'crossing ahead',
    'intersection',
    'busy traffic',
    'active road',
  ];

  /// Obstacle keywords - things in the path
  static const List<String> obstacleKeywords = [
    'stairs ahead',
    'steps ahead',
    'hole',
    'pit',
    'construction',
    'barrier ahead',
    'edge',
    'drop',
    'cliff',
    'blocked path',
  ];

  /// General danger keywords
  static const List<String> generalDangerKeywords = [
    'danger!',
    'warning!',
    'hazard',
    'fire',
    'smoke',
    'falling',
    'unstable',
    'stop now',
    'stop immediately',
  ];
}

/// Vision model configuration - HIGHLY OPTIMIZED for DeafBlind real-time
/// Performance targets: <1s response time, minimal latency
class VisionConfig {
  VisionConfig._();

  /// Vision model - lightweight and fast
  static const String visionModel = 'lfm2-vl-450m';
  
  /// Tool LLM (only if useFastMode = false)
  static const String toolCallingModel = 'qwen3-0.6';
  
  /// Max tokens - MINIMAL for fastest streaming (15-20 words)
  static const int visionMaxTokens = 25;
  
  /// Tool LLM tokens (if enabled)
  static const int toolMaxTokens = 40;
  
  /// Context size - SMALL for fast inference
  static const int contextSize = 512;
  
  /// Analysis interval - 2s optimal for safety + battery
  /// 1s = too fast (battery), 3s+ = missed hazards
  static const Duration analysisInterval = Duration(seconds: 2);
  
  /// Danger alert cooldown
  static const Duration dangerAlertCooldown = Duration(seconds: 3);
  
  /// FAST MODE = TRUE for best DeafBlind experience
  /// Skips tool LLM, uses direct vision response
  static const bool useFastMode = true;
}

/// Haptic feedback durations for different danger levels
class HapticConfig {
  HapticConfig._();
  
  /// Critical danger - long continuous vibration
  static const int criticalDurationMs = 2000;
  
  /// Danger - medium vibration
  static const int dangerDurationMs = 1500;
  
  /// Warning - short vibration
  static const int warningDurationMs = 800;
  
  /// Caution - brief vibration
  static const int cautionDurationMs = 400;
  
  /// Safe confirmation - gentle tap
  static const int safeDurationMs = 200;
  
  /// Gap between vibration pulses
  static const int pulseGapMs = 150;
  
  /// Number of pulses for danger alert
  static const int dangerPulseCount = 3;
}

/// App theme constants
class AppTheme {
  AppTheme._();

  // High contrast colors for accessibility
  static const int primaryColorValue = 0xFF1E88E5;
  static const int dangerColorValue = 0xFFD32F2F;
  static const int safeColorValue = 0xFF388E3C;
  static const int warningColorValue = 0xFFF57C00;
  static const int backgroundColorValue = 0xFF121212;
  static const int surfaceColorValue = 0xFF1E1E1E;
  static const int textColorValue = 0xFFFFFFFF;
}
