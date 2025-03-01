// Create a new file: lib/widgets/alar_branding.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AlarLogo extends StatelessWidget {
  final double size;
  final bool isAnimated;
  final Color? color;

  const AlarLogo({
    Key? key,
    this.size = 24,
    this.isAnimated = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      "ALAR",
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );

    return isAnimated
        ? textWidget
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .shimmer(duration: 3000.ms, color: Colors.white30)
        : textWidget;
  }
}

class AlarFooter extends StatelessWidget {
  final bool isMinimal;

  const AlarFooter({Key? key, this.isMinimal = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMinimal ? 4 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Powered by ",
            style: TextStyle(
              fontSize: isMinimal ? 10 : 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          Text(
            "ALAR",
            style: TextStyle(
              fontSize: isMinimal ? 10 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
