import 'dart:convert';
import 'dart:io';

class DocumentModel {
  final String id;
  String title;
  String content;
  final String filePath;
  final DateTime createdAt;
  DateTime modifiedAt;

  DocumentModel({
    required this.id,
    required this.title,
    required this.content,
    required this.filePath,
    required this.createdAt,
    required this.modifiedAt,
  });

  String get fileExtension {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < filePath.length - 1) {
      return filePath.substring(dotIndex + 1).toLowerCase();
    }
    return 'txt';
  }

  bool get isMarkdown => fileExtension == 'md' || fileExtension == 'markdown';
  bool get isCode => ['py', 'js', 'ts', 'dart', 'json', 'html', 'css', 'yaml', 'yml', 'sh', 'sql', 'c', 'cpp', 'swift'].contains(fileExtension);

  int get characterCount => content.length;
  
  int get wordCount {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  int get lineCount {
    if (content.isEmpty) return 1;
    return '\n'.allMatches(content).length + 1;
  }

  int get readingTimeMinutes {
    final words = wordCount;
    return (words / 200).ceil().clamp(1, 9999);
  }

  String get fileSizeFormatted {
    final bytes = utf8.encode(content).length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory DocumentModel.fromFile(File file, String content) {
    final stat = file.statSync();
    final name = file.uri.pathSegments.last;
    final dotIndex = name.lastIndexOf('.');
    final title = dotIndex != -1 ? name.substring(0, dotIndex) : name;
    
    return DocumentModel(
      id: file.path,
      title: title,
      content: content,
      filePath: file.path,
      createdAt: stat.changed,
      modifiedAt: stat.modified,
    );
  }

  DocumentModel copyWith({
    String? title,
    String? content,
    String? filePath,
    DateTime? modifiedAt,
  }) {
    return DocumentModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}
