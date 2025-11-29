import 'package:flutter/material.dart';

import '../../domain/entities/scene_analysis.dart';
import '../theme/app_theme.dart';

/// Widget displaying the scene description with accessibility features
/// Supports real-time streaming text display
class SceneDescriptionWidget extends StatelessWidget {
  final SceneAnalysis? analysis;
  final bool isAnalyzing;
  final bool isStreaming;
  final String streamingText;
  final bool isProcessingFrame;

  const SceneDescriptionWidget({
    super.key,
    required this.analysis,
    this.isAnalyzing = false,
    this.isStreaming = false,
    this.streamingText = '',
    this.isProcessingFrame = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine what text to show
    final displayText = _getDisplayText();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AstraTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getBorderColor(),
          width: isStreaming ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isStreaming ? Icons.auto_awesome : Icons.visibility,
                color: isStreaming ? AstraTheme.warningColor : AstraTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getHeaderText(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AstraTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isProcessingFrame || isStreaming) _buildStreamingIndicator(),
              if (isAnalyzing && !isStreaming && !isProcessingFrame)
                _buildAnalyzingIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          // Description text with streaming support
          _buildDescriptionText(displayText),
          // Detected objects (only show when not streaming)
          if (!isStreaming &&
              analysis != null &&
              analysis!.detectedObjects.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetectedObjects(analysis!.detectedObjects),
          ],
        ],
      ),
    );
  }

  /// Get the text to display based on current state
  String _getDisplayText() {
    if (isStreaming && streamingText.isNotEmpty) {
      return streamingText;
    }
    if (isProcessingFrame && streamingText.isEmpty) {
      return 'Analyzing scene...';
    }
    return analysis?.description ?? 'Waiting for scene analysis...';
  }

  /// Get header text based on state
  String _getHeaderText() {
    if (isStreaming) return 'Streaming Response';
    if (isProcessingFrame) return 'Processing Frame';
    return 'Scene Analysis';
  }

  /// Get border color based on state
  Color _getBorderColor() {
    if (isStreaming) return AstraTheme.warningColor.withValues(alpha: 0.6);
    return AstraTheme.primaryColor.withValues(alpha: 0.2);
  }

  /// Build description text with streaming animation
  Widget _buildDescriptionText(String text) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              key: ValueKey(isStreaming ? 'streaming' : analysis?.timestamp),
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AstraTheme.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Blinking cursor when streaming
          if (isStreaming) _buildTypingCursor(),
        ],
      ),
    );
  }

  /// Build blinking cursor for streaming effect
  Widget _buildTypingCursor() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value < 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 2,
            height: 20,
            margin: const EdgeInsets.only(left: 2),
            color: AstraTheme.primaryColor,
          ),
        );
      },
      onEnd: () {},
    );
  }

  /// Build streaming indicator
  Widget _buildStreamingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPulsingDot(),
        const SizedBox(width: 8),
        Text(
          isStreaming ? 'Receiving...' : 'Processing...',
          style: TextStyle(
            fontSize: 12,
            color: AstraTheme.warningColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build pulsing dot animation
  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AstraTheme.warningColor.withValues(alpha: value),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AstraTheme.primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Analyzing...',
          style: TextStyle(fontSize: 12, color: AstraTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildDetectedObjects(List<String> objects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detected Objects:',
          style: TextStyle(
            fontSize: 12,
            color: AstraTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: objects.map((obj) => _buildObjectChip(obj)).toList(),
        ),
      ],
    );
  }

  Widget _buildObjectChip(String object) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AstraTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AstraTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        object,
        style: TextStyle(
          fontSize: 12,
          color: AstraTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
