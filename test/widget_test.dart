import 'package:flutter_test/flutter_test.dart';
import 'package:text_craft/main.dart';
import 'package:text_craft/models/document_model.dart';

void main() {
  test('DocumentModel word, character and line calculation tests', () {
    final doc = DocumentModel(
      id: 'test.md',
      title: 'Test Note',
      content: '# Hello World\nThis is a test of the iOS text editor.\nLine 3',
      filePath: '/tmp/test.md',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    expect(doc.wordCount, 14);
    expect(doc.lineCount, 3);
    expect(doc.isMarkdown, true);
    expect(doc.isCode, false);
    expect(doc.fileExtension, 'md');
  });

  test('DocumentModel code file detection', () {
    final pyDoc = DocumentModel(
      id: 'script.py',
      title: 'script',
      content: 'print("hello")',
      filePath: '/tmp/script.py',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    expect(pyDoc.isCode, true);
    expect(pyDoc.isMarkdown, false);
    expect(pyDoc.fileExtension, 'py');
  });

  testWidgets('App renders DocumentListScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TextCraftApp());
    expect(find.byType(TextCraftApp), findsOneWidget);
  });
}
