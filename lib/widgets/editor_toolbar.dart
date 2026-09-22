import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class EditorToolbar extends StatelessWidget {
  final TextEditingController controller;
  final UndoHistoryController undoController;
  final VoidCallback onToggleSearch;
  final VoidCallback onTogglePreview;
  final bool isPreviewing;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.undoController,
    required this.onToggleSearch,
    required this.onTogglePreview,
    required this.isPreviewing,
  });

  void _insertOrWrap(String prefix, [String suffix = '']) {
    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid) {
      final newText = text + prefix + suffix;
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;

    if (start != end) {
      final selectedText = text.substring(start, end);
      final replaced = prefix + selectedText + suffix;
      final newText = text.replaceRange(start, end, replaced);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: end + prefix.length,
        ),
      );
    } else {
      final newText = text.replaceRange(start, end, prefix + suffix);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + prefix.length),
      );
    }
  }

  void _insertHeading() {
    final selection = controller.selection;
    final text = controller.text;
    final cursor = selection.isValid ? selection.start : text.length;

    // Find the start of current line
    final lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
    final insertPos = lineStart == -1 ? 0 : lineStart + 1;

    final newText = '${text.substring(0, insertPos)}# ${text.substring(insertPos)}';
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + 2),
    );
  }

  void _insertTab() {
    _insertOrWrap('  ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final bgColor = isDark
        ? CupertinoColors.systemBackground.resolveFrom(context).withValues(alpha: 0.95)
        : CupertinoColors.secondarySystemBackground.resolveFrom(context);
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFD1D1D6);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Undo
              ValueListenableBuilder<UndoHistoryValue>(
                valueListenable: undoController,
                builder: (context, value, _) {
                  return _ToolbarButton(
                    icon: CupertinoIcons.arrow_uturn_left,
                    onPressed: value.canUndo ? () => undoController.undo() : null,
                    tooltip: 'Undo',
                  );
                },
              ),
              // Redo
              ValueListenableBuilder<UndoHistoryValue>(
                valueListenable: undoController,
                builder: (context, value, _) {
                  return _ToolbarButton(
                    icon: CupertinoIcons.arrow_uturn_right,
                    onPressed: value.canRedo ? () => undoController.redo() : null,
                    tooltip: 'Redo',
                  );
                },
              ),
              const _ToolbarDivider(),
              // Preview toggle
              _ToolbarButton(
                icon: isPreviewing ? CupertinoIcons.pencil : CupertinoIcons.eye,
                onPressed: onTogglePreview,
                tooltip: isPreviewing ? 'Edit' : 'Preview',
                isActive: isPreviewing,
              ),
              // Search & Replace
              _ToolbarButton(
                icon: CupertinoIcons.search,
                onPressed: onToggleSearch,
                tooltip: 'Find & Replace',
              ),
              const _ToolbarDivider(),
              // Tab / Indent
              _ToolbarButton(
                text: '⇥ Tab',
                onPressed: _insertTab,
                tooltip: 'Tab (2 spaces)',
              ),
              // Markdown Heading
              _ToolbarButton(
                text: 'H1',
                onPressed: _insertHeading,
                tooltip: 'Heading',
              ),
              // Bold
              _ToolbarButton(
                text: 'B',
                isBold: true,
                onPressed: () => _insertOrWrap('**', '**'),
                tooltip: 'Bold',
              ),
              // Italic
              _ToolbarButton(
                text: 'I',
                isItalic: true,
                onPressed: () => _insertOrWrap('*', '*'),
                tooltip: 'Italic',
              ),
              // Code inline
              _ToolbarButton(
                text: '`',
                onPressed: () => _insertOrWrap('`', '`'),
                tooltip: 'Inline Code',
              ),
              // Code block
              _ToolbarButton(
                text: '```',
                onPressed: () => _insertOrWrap('```\n', '\n```'),
                tooltip: 'Code Block',
              ),
              // Bullet list
              _ToolbarButton(
                icon: CupertinoIcons.list_bullet,
                onPressed: () => _insertOrWrap('- '),
                tooltip: 'Bullet List',
              ),
              // Checkbox list
              _ToolbarButton(
                icon: CupertinoIcons.check_mark_circled,
                onPressed: () => _insertOrWrap('- [ ] '),
                tooltip: 'Task List',
              ),
              // Quote
              _ToolbarButton(
                icon: CupertinoIcons.quote_bubble,
                onPressed: () => _insertOrWrap('> '),
                tooltip: 'Blockquote',
              ),
              // Link
              _ToolbarButton(
                icon: CupertinoIcons.link,
                onPressed: () => _insertOrWrap('[', '](url)'),
                tooltip: 'Link',
              ),
              const _ToolbarDivider(),
              // Quick coding brackets
              _ToolbarButton(
                text: '( )',
                onPressed: () => _insertOrWrap('(', ')'),
              ),
              _ToolbarButton(
                text: '{ }',
                onPressed: () => _insertOrWrap('{', '}'),
              ),
              _ToolbarButton(
                text: '[ ]',
                onPressed: () => _insertOrWrap('[', ']'),
              ),
              _ToolbarButton(
                text: '" "',
                onPressed: () => _insertOrWrap('"', '"'),
              ),
              _ToolbarButton(
                text: '=',
                onPressed: () => _insertOrWrap(' = '),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isBold;
  final bool isItalic;
  final bool isActive;

  const _ToolbarButton({
    this.icon,
    this.text,
    this.onPressed,
    this.tooltip,
    this.isBold = false,
    this.isItalic = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final enabled = onPressed != null;

    Color iconColor;
    if (!enabled) {
      iconColor = CupertinoColors.inactiveGray;
    } else if (isActive) {
      iconColor = primaryColor;
    } else {
      iconColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    }

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: const Size(36, 36),
      onPressed: onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: isActive
            ? BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: icon != null
            ? Icon(icon, size: 20, color: iconColor)
            : Text(
                text ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  fontFamily: text != null && text!.contains(RegExp(r'[\{\}\[\]\(\)`=]')) ? 'Courier' : null,
                  color: iconColor,
                ),
              ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? const Color(0xFF38383A) : const Color(0xFFC7C7CC),
    );
  }
}
