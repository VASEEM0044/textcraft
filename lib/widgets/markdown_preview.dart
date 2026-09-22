import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownPreview extends StatelessWidget {
  final String data;
  final ScrollController? scrollController;

  const MarkdownPreview({
    super.key,
    required this.data,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    final baseTextStyle = TextStyle(
      fontSize: 16,
      height: 1.6,
      color: isDark ? CupertinoColors.white : CupertinoColors.black,
    );

    return CupertinoScrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: MarkdownBody(
          data: data.isEmpty ? '*No content to preview*' : data,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: baseTextStyle,
            h1: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            h2: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            h3: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
            h2Padding: const EdgeInsets.only(top: 14, bottom: 6),
            h3Padding: const EdgeInsets.only(top: 10, bottom: 4),
            blockquote: TextStyle(
              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
              fontStyle: FontStyle.italic,
              fontSize: 15,
            ),
            blockquoteDecoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: primaryColor,
                  width: 3.5,
                ),
              ),
            ),
            blockquotePadding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
            code: TextStyle(
              fontFamily: 'Courier',
              fontSize: 14,
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
              color: isDark ? const Color(0xFFFF9F0A) : const Color(0xFFD70015),
            ),
            codeblockPadding: const EdgeInsets.all(12),
            codeblockDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
              ),
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
                  width: 0.8,
                ),
              ),
            ),
            listBullet: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
            a: TextStyle(
              color: primaryColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
