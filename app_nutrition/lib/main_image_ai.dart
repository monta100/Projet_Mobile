// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'Screens/analyze_image_test.dart';

/// 🎯 Ce main est uniquement pour tester la fonctionnalité d’analyse d’image IA
/// Il n'affecte pas ton application principale.

void main() {
  runApp(const ImageAITestApp());
}

class ImageAITestApp extends StatelessWidget {
  const ImageAITestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Test IA Image - Snacky 🍊',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const AnalyzeImageTest(),
    );
  }
}
