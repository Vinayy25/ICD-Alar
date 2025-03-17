// Add this widget class to your file
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ExpandableDefinition extends StatefulWidget {
  final String? definitionText;
  final BuildContext parentContext;

  const ExpandableDefinition({
    super.key,
    required this.definitionText,
    required this.parentContext,
  });

  @override
  State<ExpandableDefinition> createState() => _ExpandableDefinitionState();
}

class _ExpandableDefinitionState extends State<ExpandableDefinition>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _heightFactor;

  // The text style for definition content
  TextStyle get _textStyle =>
      Theme.of(widget.parentContext).textTheme.bodyMedium!;

  // Calculate if the text will exceed 3 lines
  bool _needsExpansion = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightFactor = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Start in collapsed state
    _animationController.value = 0;

    // Check text length to determine if expansion is needed
    // This is a rough estimate; we'll measure precisely in build
    if (widget.definitionText != null) {
      final estimatedLineCount =
          widget.definitionText!.length / 40; // ~40 chars per line
      _needsExpansion = estimatedLineCount > 3;
    }

    // Always start collapsed if expansion is needed
    if (_needsExpansion) {
      _isExpanded = false;
    } else {
      _isExpanded = true;
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // No need for expandable logic if the content is markdown
    if (widget.definitionText?.trim().startsWith('!markdown') ?? false) {
      return _buildDefinitionWidget(context, widget.definitionText);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure if text would overflow 3 lines
        final textSpan = TextSpan(
          text: widget.definitionText ?? 'No definition available',
          style: _textStyle,
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 3,
        )..layout(maxWidth: constraints.maxWidth - 32); // 32 for padding

        final overflows = textPainter.didExceedMaxLines;
        _needsExpansion = overflows;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card with animated height
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Always visible content (up to 3 lines)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.definitionText ?? 'No definition available',
                        style: _textStyle,
                        maxLines: _isExpanded ? null : 3,
                        overflow: _isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ),

                    // Expandable content (rest of text)
                    if (_needsExpansion)
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(
                              bottom: 16.0, left: 16.0, right: 16.0),
                          child: Text(
                            widget.definitionText ?? '',
                            style: _textStyle,
                          ),
                        ),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                        sizeCurve: Curves.easeInOut,
                        // Use zero height for first child to prevent layout jumps
                        firstCurve: const Threshold(0),
                        secondCurve: const Threshold(1),
                      ),

                    // Expand/Collapse button
                    if (_needsExpansion)
                      InkWell(
                        onTap: _toggleExpanded,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'Read less' : 'Read more',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AnimatedRotation(
                                  turns: _isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefinitionWidget(BuildContext context, String? definitionText) {
    if (definitionText == null) {
      return Text('No definition available');
    }

    // Check if the definition is in markdown format
    if (definitionText.trim().startsWith('!markdown')) {
      // Remove the !markdown marker and render as markdown
      final markdownContent =
          definitionText.replaceFirst('!markdown', '').trim();
      return MarkdownBody(
        data: markdownContent,
        styleSheet: MarkdownStyleSheet(
          p: Theme.of(context).textTheme.bodyMedium,
          h1: Theme.of(context).textTheme.headlineSmall,
          h2: Theme.of(context).textTheme.titleLarge,
          h3: Theme.of(context).textTheme.titleMedium,
          strong: const TextStyle(fontWeight: FontWeight.bold),
          em: const TextStyle(fontStyle: FontStyle.italic),
          blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
          code: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.shade200,
              ),
        ),
      );
    }

    // Regular text definition
    return Text(
      definitionText,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
