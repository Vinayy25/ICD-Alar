import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as htmlDom;

class HtmlText extends StatelessWidget {
  final String htmlString;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final int? maxLines;

  const HtmlText(
    this.htmlString, {
    Key? key,
    this.style,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse the HTML
    final document = htmlParser.parse(htmlString);
    final htmlElements = document.body!.nodes;

    // Convert to rich text
    final spans = _buildSpans(htmlElements, style);

    return RichText(
      text: TextSpan(
        children: spans,
        style: style ?? DefaultTextStyle.of(context).style,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  List<InlineSpan> _buildSpans(List<htmlDom.Node> nodes, TextStyle? baseStyle) {
    final List<InlineSpan> spans = [];

    for (final node in nodes) {
      if (node is htmlDom.Element) {
        if (node.localName == 'em' && node.classes.contains('found')) {
          // Handle highlighted search terms
          spans.add(
            TextSpan(
              text: node.text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.yellow.withOpacity(0.3),
              ),
            ),
          );
        } else if (node.localName == 'b' || node.localName == 'strong') {
          // Handle bold text
          spans.add(
            TextSpan(
              text: node.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        } else if (node.localName == 'i' || node.localName == 'em') {
          // Handle italic text
          spans.add(
            TextSpan(
              text: node.text,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          );
        } else {
          // Handle other elements recursively
          spans.addAll(_buildSpans(node.nodes, baseStyle));
        }
      } else if (node is htmlDom.Text) {
        // Handle plain text
        spans.add(TextSpan(text: node.text));
      }
    }

    return spans;
  }
}