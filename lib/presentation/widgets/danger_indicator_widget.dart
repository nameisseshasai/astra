import 'package:flutter/material.dart';

import '../../core/utils/danger_detector.dart';
import '../theme/app_theme.dart';

/// Widget displaying the current danger level with visual indicators
class DangerIndicatorWidget extends StatelessWidget {
  final DangerInfo dangerInfo;
  final bool animate;

  const DangerIndicatorWidget({
    super.key,
    required this.dangerInfo,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final priority = DangerDetector.getDangerPriority(dangerInfo.level);
    final color = AstraTheme.getDangerColor(priority);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          // Danger icon with pulse animation
          _PulsingIcon(
            icon: _getDangerIcon(dangerInfo.type),
            color: color,
            shouldPulse: animate && dangerInfo.level != DangerLevel.safe,
          ),
          const SizedBox(width: 16),
          // Danger info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDangerTitle(dangerInfo.level),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dangerInfo.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AstraTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Danger level indicator
          _DangerLevelIndicator(level: priority),
        ],
      ),
    );
  }

  IconData _getDangerIcon(DangerType type) {
    return switch (type) {
      DangerType.none => Icons.check_circle_outline,
      DangerType.vehicle => Icons.directions_car,
      DangerType.water => Icons.water_drop,
      DangerType.road => Icons.edit_road,
      DangerType.obstacle => Icons.warning_amber,
      DangerType.general => Icons.dangerous,
    };
  }

  String _getDangerTitle(DangerLevel level) {
    return switch (level) {
      DangerLevel.safe => 'SAFE',
      DangerLevel.caution => 'CAUTION',
      DangerLevel.warning => 'WARNING',
      DangerLevel.danger => 'DANGER',
      DangerLevel.critical => 'CRITICAL DANGER',
    };
  }
}

/// Pulsing icon widget for danger alerts
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool shouldPulse;

  const _PulsingIcon({
    required this.icon,
    required this.color,
    required this.shouldPulse,
  });

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.shouldPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.shouldPulse ? _scaleAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: widget.shouldPulse
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(widget.icon, size: 32, color: widget.color),
          ),
        );
      },
    );
  }
}

/// Visual indicator showing danger level bars
class _DangerLevelIndicator extends StatelessWidget {
  final int level;

  const _DangerLevelIndicator({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index < level;
        final color = isActive
            ? AstraTheme.getDangerColor(level)
            : AstraTheme.cardColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(left: 4),
          width: 8,
          height: 24 + (index * 4).toDouble(),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
