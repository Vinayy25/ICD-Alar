// Add this widget class to your ClipboardScreen file
import 'package:flutter/material.dart';

class ExpandableDescription extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const ExpandableDescription({
    Key? key,
    required this.text,
    this.style,
  }) : super(key: key);

  @override
  State<ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<ExpandableDescription>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  final int _maxLines = 2;
  bool _hasOverflow = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use TextPainter to determine if text will overflow
        final textSpan = TextSpan(
          text: widget.text,
          style: widget.style ?? theme.textTheme.bodyMedium,
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        _hasOverflow = textPainter.didExceedMaxLines;

        // If no overflow, just render regular text
        if (!_hasOverflow) {
          return Text(widget.text,
              style: widget.style ?? theme.textTheme.bodyMedium);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                child: Text(
                  widget.text,
                  style: widget.style ?? theme.textTheme.bodyMedium,
                  maxLines: _expanded ? null : _maxLines,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Show "Read more" button only if text overflows
            GestureDetector(
              onTap: _toggleExpand,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? "Show less" : "Read more",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.rotate(
                        angle: _animation.value * 3.14159,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
