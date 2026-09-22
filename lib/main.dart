import 'package:flutter/cupertino.dart';
import 'screens/document_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TextCraftApp());
}

class TextCraftApp extends StatelessWidget {
  const TextCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'TextCraft',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: DocumentListScreen(),
    );
  }
}
