import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config.dart';
import 'screens/home_screen.dart';
import 'state/letter_book.dart';
import 'theme.dart';
import 'widgets/preview_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final book = await LetterBook.load();
  runApp(LetterApp(book: book));
}

class LetterApp extends StatelessWidget {
  const LetterApp({super.key, required this.book});

  final LetterBook book;

  @override
  Widget build(BuildContext context) {
    return LetterBookScope(
      book: book,
      child: MaterialApp(
        title: LetterConfig.appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => PreviewBanner(child: child!),
        home: const HomeScreen(),
      ),
    );
  }
}
