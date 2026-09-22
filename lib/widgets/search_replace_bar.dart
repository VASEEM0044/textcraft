import 'package:flutter/cupertino.dart';

class SearchReplaceBar extends StatefulWidget {
  final TextEditingController textController;
  final VoidCallback onClose;

  const SearchReplaceBar({
    super.key,
    required this.textController,
    required this.onClose,
  });

  @override
  State<SearchReplaceBar> createState() => _SearchReplaceBarState();
}

class _SearchReplaceBarState extends State<SearchReplaceBar> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final List<int> _matchIndices = [];
  int _currentMatchIndex = -1;
  bool _showReplace = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
    widget.textController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text;
    final text = widget.textController.text;
    _matchIndices.clear();

    if (query.isNotEmpty) {
      int startIndex = 0;
      while (true) {
        final index = text.toLowerCase().indexOf(query.toLowerCase(), startIndex);
        if (index == -1) break;
        _matchIndices.add(index);
        startIndex = index + query.length;
      }
    }

    if (_matchIndices.isEmpty) {
      _currentMatchIndex = -1;
    } else if (_currentMatchIndex >= _matchIndices.length || _currentMatchIndex == -1) {
      _currentMatchIndex = 0;
      _highlightCurrentMatch();
    }

    setState(() {});
  }

  void _highlightCurrentMatch() {
    if (_currentMatchIndex >= 0 && _currentMatchIndex < _matchIndices.length) {
      final start = _matchIndices[_currentMatchIndex];
      final length = _searchController.text.length;
      widget.textController.selection = TextSelection(
        baseOffset: start,
        extentOffset: start + length,
      );
    }
  }

  void _nextMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchIndices.length;
    });
    _highlightCurrentMatch();
  }

  void _previousMatch() {
    if (_matchIndices.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matchIndices.length) % _matchIndices.length;
    });
    _highlightCurrentMatch();
  }

  void _replaceOne() {
    if (_currentMatchIndex < 0 || _currentMatchIndex >= _matchIndices.length) return;
    final query = _searchController.text;
    final replacement = _replaceController.text;
    final start = _matchIndices[_currentMatchIndex];

    final currentText = widget.textController.text;
    final newText = currentText.replaceRange(start, start + query.length, replacement);
    widget.textController.text = newText;
  }

  void _replaceAll() {
    final query = _searchController.text;
    if (query.isEmpty) return;
    final replacement = _replaceController.text;
    final currentText = widget.textController.text;
    
    // Case insensitive replace all
    final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
    final newText = currentText.replaceAll(pattern, replacement);
    widget.textController.text = newText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Find in document',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _matchIndices.isEmpty
                    ? (_searchController.text.isEmpty ? '' : '0/0')
                    : '${_currentMatchIndex + 1}/${_matchIndices.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(32, 32),
                onPressed: _matchIndices.isEmpty ? null : _previousMatch,
                child: const Icon(CupertinoIcons.chevron_up, size: 18),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(32, 32),
                onPressed: _matchIndices.isEmpty ? null : _nextMatch,
                child: const Icon(CupertinoIcons.chevron_down, size: 18),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(32, 32),
                onPressed: () => setState(() => _showReplace = !_showReplace),
                child: Icon(
                  CupertinoIcons.arrow_2_squarepath,
                  size: 18,
                  color: _showReplace ? CupertinoTheme.of(context).primaryColor : null,
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(32, 32),
                onPressed: widget.onClose,
                child: const Icon(CupertinoIcons.clear_thick, size: 16),
              ),
            ],
          ),
          if (_showReplace) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _replaceController,
                    placeholder: 'Replace with',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(32, 32),
                  onPressed: _matchIndices.isEmpty ? null : _replaceOne,
                  child: const Text('Replace', style: TextStyle(fontSize: 13)),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(32, 32),
                  onPressed: _matchIndices.isEmpty ? null : _replaceAll,
                  child: const Text('All', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
