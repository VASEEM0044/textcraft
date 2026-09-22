import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../models/document_model.dart';
import '../services/file_service.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/markdown_preview.dart';
import '../widgets/search_replace_bar.dart';

enum EditorFontFamily { system, monospace, serif }

class EditorScreen extends StatefulWidget {
  final DocumentModel document;

  const EditorScreen({
    super.key,
    required this.document,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late DocumentModel _document;
  late TextEditingController _textController;
  late TextEditingController _titleController;
  final UndoHistoryController _undoController = UndoHistoryController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _isPreviewMode = false;
  bool _showSearch = false;
  bool _showLineNumbers = false;

  double _fontSize = 16.0;
  EditorFontFamily _fontFamily = EditorFontFamily.system;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _textController = TextEditingController(text: _document.content);
    _titleController = TextEditingController(text: _document.title);

    _textController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    _titleController.dispose();
    _undoController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      _saveContent();
    });
  }

  Future<void> _saveContent() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    _document.content = _textController.text;
    await FileService().saveDocument(_document);
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  void _renameDocument() {
    _titleController.text = _document.title;
    showCupertinoDialog(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Rename Document'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: _titleController,
              autofocus: true,
              placeholder: 'Document Title',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final newTitle = _titleController.text.trim();
                Navigator.pop(ctx);
                if (newTitle.isNotEmpty && newTitle != _document.title) {
                  final updated = await FileService().renameDocument(_document, newTitle);
                  setState(() => _document = updated);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showStatsModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: Text(_document.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          message: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _StatRow(label: 'Words', value: '${_document.wordCount}'),
              _StatRow(label: 'Characters', value: '${_document.characterCount}'),
              _StatRow(label: 'Lines', value: '${_document.lineCount}'),
              _StatRow(label: 'Reading Time', value: '~${_document.readingTimeMinutes} min'),
              _StatRow(label: 'File Size', value: _document.fileSizeFormatted),
              _StatRow(label: 'Format', value: '.${_document.fileExtension.toUpperCase()}'),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _share();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.share, size: 20),
                  SizedBox(width: 8),
                  Text('Share via AirDrop / Files'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        );
      },
    );
  }

  void _showSettingsSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return CupertinoActionSheet(
              title: const Text('Editor Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
              message: Column(
                children: [
                  const SizedBox(height: 12),
                  // Font Size
                  Row(
                    children: [
                      const Text('Text Size:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('${_fontSize.toInt()} pt', style: const TextStyle(color: CupertinoColors.systemGrey)),
                    ],
                  ),
                  CupertinoSlider(
                    value: _fontSize,
                    min: 12.0,
                    max: 28.0,
                    divisions: 16,
                    onChanged: (val) {
                      setSheetState(() => _fontSize = val);
                      setState(() => _fontSize = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Font style selector
                  Row(
                    children: [
                      const Text('Typography:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      CupertinoSlidingSegmentedControl<EditorFontFamily>(
                        groupValue: _fontFamily,
                        children: const {
                          EditorFontFamily.system: Text('Default', style: TextStyle(fontSize: 12)),
                          EditorFontFamily.monospace: Text('Mono', style: TextStyle(fontSize: 12)),
                          EditorFontFamily.serif: Text('Serif', style: TextStyle(fontSize: 12)),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            setSheetState(() => _fontFamily = val);
                            setState(() => _fontFamily = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Line numbers toggle
                  Row(
                    children: [
                      const Text('Line Numbers:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      CupertinoSwitch(
                        value: _showLineNumbers,
                        onChanged: (val) {
                          setSheetState(() => _showLineNumbers = val);
                          setState(() => _showLineNumbers = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              cancelButton: CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            );
          },
        );
      },
    );
  }

  void _share() {
    _saveContent();
    FileService().shareDocument(_document);
  }

  TextStyle _getTextStyle() {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    String? fontFamily;
    if (_fontFamily == EditorFontFamily.monospace || _document.isCode) {
      fontFamily = 'Courier';
    } else if (_fontFamily == EditorFontFamily.serif) {
      fontFamily = 'Georgia';
    }

    return TextStyle(
      fontSize: _fontSize,
      height: 1.5,
      fontFamily: fontFamily,
      color: isDark ? CupertinoColors.white : CupertinoColors.black,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: GestureDetector(
          onTap: _renameDocument,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _document.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.pencil_circle,
                size: 16,
                color: CupertinoColors.inactiveGray.resolveFrom(context),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save status indicator
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isSaving ? 1.0 : 0.0,
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: CupertinoActivityIndicator(radius: 8),
              ),
            ),
            // Info / Stats
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(36, 36),
              onPressed: _showStatsModal,
              child: const Icon(CupertinoIcons.info_circle, size: 22),
            ),
            // Settings
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(36, 36),
              onPressed: _showSettingsSheet,
              child: const Icon(CupertinoIcons.textformat, size: 22),
            ),
            // Share
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(36, 36),
              onPressed: _share,
              child: const Icon(CupertinoIcons.share, size: 22),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search & Replace bar if active
            if (_showSearch)
              SearchReplaceBar(
                textController: _textController,
                onClose: () => setState(() => _showSearch = false),
              ),

            // Mode Toggle tab if Markdown document
            if (_document.isMarkdown)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                      width: 0.5,
                    ),
                  ),
                ),
                child: CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _isPreviewMode,
                  children: const {
                    false: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.pencil, size: 16),
                          SizedBox(width: 6),
                          Text('Edit', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    true: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.eye, size: 16),
                          SizedBox(width: 6),
                          Text('Preview', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) setState(() => _isPreviewMode = val);
                  },
                ),
              ),

            // Main Editor or Markdown Preview
            Expanded(
              child: _isPreviewMode
                  ? MarkdownPreview(data: _textController.text)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line numbers gutter
                        if (_showLineNumbers)
                          _LineNumbersGutter(
                            textController: _textController,
                            fontSize: _fontSize,
                            isDark: isDark,
                          ),
                        // Text editing area
                        Expanded(
                          child: CupertinoScrollbar(
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: CupertinoTextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const BoxDecoration(color: CupertinoColors.transparent),
                                style: _getTextStyle(),
                                placeholder: 'Start writing...',
                                cursorColor: primaryColor,
                                autocorrect: !_document.isCode,
                                enableSuggestions: !_document.isCode,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Bottom accessory toolbar
            if (!_isPreviewMode)
              EditorToolbar(
                controller: _textController,
                undoController: _undoController,
                onToggleSearch: () => setState(() => _showSearch = !_showSearch),
                onTogglePreview: () => setState(() => _isPreviewMode = !_isPreviewMode),
                isPreviewing: _isPreviewMode,
              ),
          ],
        ),
      ),
    );
  }
}

class _LineNumbersGutter extends StatelessWidget {
  final TextEditingController textController;
  final double fontSize;
  final bool isDark;

  const _LineNumbersGutter({
    required this.textController,
    required this.fontSize,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: textController,
      builder: (context, value, _) {
        final lineCount = '\n'.allMatches(value.text).length + 1;
        final lines = List.generate(lineCount, (i) => '${i + 1}').join('\n');

        return Container(
          padding: const EdgeInsets.only(left: 10, right: 8, top: 12),
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
          ),
          child: Text(
            lines,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: fontSize,
              height: 1.5,
              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey3,
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
