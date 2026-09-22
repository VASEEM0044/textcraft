import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/document_model.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  Future<Directory> get _docsDir async {
    return await getApplicationDocumentsDirectory();
  }

  Future<List<DocumentModel>> loadDocuments() async {
    final dir = await _docsDir;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final entities = dir.listSync();
    final List<DocumentModel> documents = [];

    for (final entity in entities) {
      if (entity is File) {
        // Skip hidden or system files
        final filename = entity.uri.pathSegments.last;
        if (filename.startsWith('.')) continue;

        try {
          final content = await entity.readAsString();
          documents.add(DocumentModel.fromFile(entity, content));
        } catch (_) {
          // If binary or unreadable as text, skip
        }
      }
    }

    // Sort by modified date descending (newest first)
    documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return documents;
  }

  Future<DocumentModel> createDocument({
    String? title,
    String extension = 'txt',
    String initialContent = '',
  }) async {
    final dir = await _docsDir;
    String baseTitle = title?.trim().isNotEmpty == true ? title!.trim() : 'Untitled Note';
    String filename = '$baseTitle.$extension';
    File file = File('${dir.path}/$filename');

    int counter = 1;
    while (await file.exists()) {
      filename = '$baseTitle $counter.$extension';
      file = File('${dir.path}/$filename');
      counter++;
    }

    await file.writeAsString(initialContent);
    return DocumentModel.fromFile(file, initialContent);
  }

  Future<void> saveDocument(DocumentModel document) async {
    final file = File(document.filePath);
    await file.writeAsString(document.content);
    document.modifiedAt = DateTime.now();
  }

  Future<void> deleteDocument(DocumentModel document) async {
    final file = File(document.filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<DocumentModel> renameDocument(DocumentModel document, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty || trimmed == document.title) return document;

    final dir = await _docsDir;
    final ext = document.fileExtension;
    String newFilename = '$trimmed.$ext';
    File targetFile = File('${dir.path}/$newFilename');

    int counter = 1;
    while (await targetFile.exists() && targetFile.path != document.filePath) {
      newFilename = '$trimmed $counter.$ext';
      targetFile = File('${dir.path}/$newFilename');
      counter++;
    }

    final oldFile = File(document.filePath);
    if (await oldFile.exists()) {
      await oldFile.rename(targetFile.path);
    } else {
      await targetFile.writeAsString(document.content);
    }

    document.title = trimmed;
    return DocumentModel.fromFile(targetFile, document.content);
  }

  Future<DocumentModel> duplicateDocument(DocumentModel document) async {
    return await createDocument(
      title: '${document.title} Copy',
      extension: document.fileExtension,
      initialContent: document.content,
    );
  }

  Future<DocumentModel?> importDocument() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'markdown', 'py', 'js', 'ts', 'dart', 'json', 'html', 'css', 'yaml', 'yml', 'sh', 'sql', 'c', 'cpp', 'swift'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final pickedFile = File(files.first.path!);
      final content = await pickedFile.readAsString();
      final originalName = pickedFile.uri.pathSegments.last;
      
      final dotIndex = originalName.lastIndexOf('.');
      final title = dotIndex != -1 ? originalName.substring(0, dotIndex) : originalName;
      final ext = dotIndex != -1 ? originalName.substring(dotIndex + 1) : 'txt';

      return await createDocument(
        title: title,
        extension: ext,
        initialContent: content,
      );
    }
    return null;
  }

  Future<void> shareDocument(DocumentModel document, {Rect? sharePositionOrigin}) async {
    final file = File(document.filePath);
    if (!await file.exists()) {
      await file.writeAsString(document.content);
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: document.title,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<void> seedInitialTemplatesIfEmpty() async {
    final docs = await loadDocuments();
    if (docs.isNotEmpty) return;

    await createDocument(
      title: 'Welcome to TextCraft',
      extension: 'md',
      initialContent: '''# Welcome to TextCraft for iOS! ✍️

A clean, distraction-free markdown and text editor designed specifically for iPhone and iPad.

## 🚀 Key Features
- **Pure Native iOS Experience**: Smooth Cupertino UI with dynamic Light & Dark mode.
- **Markdown & Code Support**: Full markdown formatting, code syntax, and real-time preview.
- **Accompanying Keyboard Bar**: Quick access to `#`, `*`, `code`, indentation, and punctuation.
- **Undo / Redo & Find / Replace**: Never worry about mistakes.
- **Files App Integration**: Documents are stored in your device storage and can be accessed directly from the iOS **Files** app!
- **Native iOS Share Sheet**: Export & share via AirDrop, Messages, Mail, or Save to Files.

---

### Quick Markdown Demo
You can format text with **bold**, *italics*, or `inline code`.

```swift
// Swift code example
import SwiftUI

struct GreetingView: View {
    var body: some View {
        Text("Hello from iPhone!")
            .font(.title)
    }
}
```

- [x] Create first note
- [ ] Try Markdown Preview mode
- [ ] Share with AirDrop or Files app

Enjoy writing!
''',
    );

    await createDocument(
      title: 'Quick Scratchpad',
      extension: 'txt',
      initialContent: '''Meeting Notes & Ideas:
- Discuss new mobile design system
- Check performance on iPhone 15 Pro
- Plan release schedule for App Store & Sideloadly
''',
    );
  }
}
