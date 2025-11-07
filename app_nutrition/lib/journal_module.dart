
import 'package:app_nutrition/journal/ui/journal_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JournalModule {
  static Map<String, WidgetBuilder> routes() => {
        '/journal': (_) => const ProviderScope(child: JournalHomePage()),
      };
}