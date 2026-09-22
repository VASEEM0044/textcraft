import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/document_model.dart';
import '../services/file_service.dart';
import 'editor_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final FileService _fileService = FileService();
  List<DocumentModel> _allDocuments = [];
  List<DocumentModel> _filteredDocuments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Markdown, 2: Text, 3: Code

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    await _fileService.seedInitialTemplatesIfEmpty();
    final docs = await _fileService.loadDocuments();
    if (!mounted) return;
    setState(() {
      _allDocuments = docs;
      _isLoading = false;
    });
    _filterDocuments();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
    _filterDocuments();
  }

  void _filterDocuments() {
    setState(() {
      _filteredDocuments = _allDocuments.where((doc) {
        // Category filter
        bool matchesCategory = true;
        if (_selectedFilterIndex == 1) {
          matchesCategory = doc.isMarkdown;
        } else if (_selectedFilterIndex == 2) {
          matchesCategory = !doc.isMarkdown && !doc.isCode;
        } else if (_selectedFilterIndex == 3) {
          matchesCategory = doc.isCode;
        }

        if (!matchesCategory) return false;

        // Search query filter
        if (_searchQuery.isEmpty) return true;
        return doc.title.toLowerCase().contains(_searchQuery) ||
            doc.content.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  void _openEditor(DocumentModel doc) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => EditorScreen(document: doc),
      ),
    );
    _loadDocuments();
  }

  void _createNewDocument({String extension = 'txt', String? templateTitle, String initialContent = ''}) async {
    final doc = await _fileService.createDocument(
      title: templateTitle,
      extension: extension,
      initialContent: initialContent,
    );
    _openEditor(doc);
  }

  void _showNewDocumentSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: const Text('Create New Document', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _createNewDocument(extension: 'txt', templateTitle: 'New Note');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_text, size: 20),
                  SizedBox(width: 8),
                  Text('Plain Text (.txt)'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _createNewDocument(
                  extension: 'md',
                  templateTitle: 'New Document',
                  initialContent: '# Title\n\nStart writing markdown here...\n',
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_richtext, size: 20),
                  SizedBox(width: 8),
                  Text('Markdown Note (.md)'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _createNewDocument(
                  extension: 'py',
                  templateTitle: 'script',
                  initialContent: '#!/usr/bin/env python3\n\ndef main():\n    print("Hello, world!")\n\nif __name__ == "__main__":\n    main()\n',
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.chevron_left_slash_chevron_right, size: 20),
                  SizedBox(width: 8),
                  Text('Code File (.py / .js)'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(ctx);
                final doc = await _fileService.importDocument();
                if (doc != null) {
                  _openEditor(doc);
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.folder_badge_plus, size: 20),
                  SizedBox(width: 8),
                  Text('Import from Files App...'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _confirmDelete(DocumentModel doc) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Delete Document?'),
          content: Text('Are you sure you want to delete "${doc.title}"? This cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                await _fileService.deleteDocument(doc);
                _loadDocuments();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _duplicate(DocumentModel doc) async {
    await _fileService.duplicateDocument(doc);
    _loadDocuments();
  }

  Widget _buildDocIcon(DocumentModel doc, bool isDark) {
    IconData iconData;
    Color iconColor;

    if (doc.isMarkdown) {
      iconData = CupertinoIcons.doc_richtext;
      iconColor = CupertinoColors.systemIndigo;
    } else if (doc.isCode) {
      iconData = CupertinoIcons.chevron_left_slash_chevron_right;
      iconColor = CupertinoColors.systemGreen;
    } else {
      iconData = CupertinoIcons.doc_text;
      iconColor = CupertinoColors.systemBlue;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Documents'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: _showNewDocumentSheet,
              child: const Icon(CupertinoIcons.plus_circle_fill, size: 28),
            ),
          ),
          CupertinoSliverRefreshControl(
            onRefresh: _loadDocuments,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Search field
                  CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search files and notes',
                  ),
                  const SizedBox(height: 12),
                  // Filter segments
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _selectedFilterIndex,
                      children: const {
                        0: Text('All', style: TextStyle(fontSize: 13)),
                        1: Text('Markdown', style: TextStyle(fontSize: 13)),
                        2: Text('Text', style: TextStyle(fontSize: 13)),
                        3: Text('Code', style: TextStyle(fontSize: 13)),
                      },
                      onValueChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFilterIndex = val);
                          _filterDocuments();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_filteredDocuments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_search,
                        size: 64,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'No Matching Documents' : 'No Documents Yet',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Try a different search term or category filter'
                            : 'Tap + above to start writing your first note or document',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_searchQuery.isEmpty)
                        CupertinoButton.filled(
                          onPressed: _showNewDocumentSheet,
                          child: const Text('Create New Document'),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = _filteredDocuments[index];
                    final dateFormatted = DateFormat.yMMMd().format(doc.modifiedAt);
                    final previewSnippet = doc.content
                        .trim()
                        .replaceAll('\n', ' ')
                        .replaceAll(RegExp(r'#+\s*'), '');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CupertinoContextMenu(
                        actions: [
                          CupertinoContextMenuAction(
                            onPressed: () {
                              Navigator.pop(context);
                              _openEditor(doc);
                            },
                            trailingIcon: CupertinoIcons.pencil,
                            child: const Text('Open'),
                          ),
                          CupertinoContextMenuAction(
                            onPressed: () {
                              Navigator.pop(context);
                              _duplicate(doc);
                            },
                            trailingIcon: CupertinoIcons.doc_on_doc,
                            child: const Text('Duplicate'),
                          ),
                          CupertinoContextMenuAction(
                            onPressed: () {
                              Navigator.pop(context);
                              FileService().shareDocument(doc);
                            },
                            trailingIcon: CupertinoIcons.share,
                            child: const Text('Share'),
                          ),
                          CupertinoContextMenuAction(
                            isDestructiveAction: true,
                            onPressed: () {
                              Navigator.pop(context);
                              _confirmDelete(doc);
                            },
                            trailingIcon: CupertinoIcons.delete,
                            child: const Text('Delete'),
                          ),
                        ],
                        child: GestureDetector(
                          onTap: () => _openEditor(doc),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildDocIcon(doc, isDark),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              doc.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isDark ? CupertinoColors.white : CupertinoColors.black).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              doc.fileExtension.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        previewSnippet.isNotEmpty ? previewSnippet : 'Empty document',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            dateFormatted,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('•', style: TextStyle(color: CupertinoColors.systemGrey)),
                                          const SizedBox(width: 8),
                                          Text(
                                            doc.fileSizeFormatted,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('•', style: TextStyle(color: CupertinoColors.systemGrey)),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${doc.wordCount} words',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 16,
                                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _filteredDocuments.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
