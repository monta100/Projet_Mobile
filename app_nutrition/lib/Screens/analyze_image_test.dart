// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Services/image_ai_analysis_service.dart';
import 'package:flutter/foundation.dart';
import '../Theme/app_colors.dart';

class AnalyzeImageTest extends StatefulWidget {
  const AnalyzeImageTest({super.key});

  @override
  State<AnalyzeImageTest> createState() => _AnalyzeImageTestState();
}

class _AnalyzeImageTestState extends State<AnalyzeImageTest> {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  String _result = "";
  bool _isLoading = false;

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _isLoading = true;
      _result = "Analyse en cours… 🔍";
      _imageFile = File(picked.path);
    });

    // Utilise compute + Gemini (clé dans .env)
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    final res = await compute(
      analyzeImageInIsolate,
      ImageAnalysisParams(imagePath: picked.path, apiKey: key),
    );

    setState(() {
      _isLoading = false;
      _result = _normalizeResult(res);
    });
  }

  String _normalizeResult(String s) {
    var out = s.trim();
    // Collapse duplicate commas and spaces
    out = out.replaceAll(RegExp(r',[,\s]+'), ', ');
    out = out.replaceAll(RegExp(r'\s+'), ' ');
    out = out.replaceAll(RegExp(r'\s+,\s*'), ', ');
    // Remove trailing commas or punctuation duplicates
    out = out.replaceAll(RegExp(r'[,:;\.-]{2,}'), '.');
    out = out.replaceAll(RegExp(r'[,:;]$'), '');
    // If the model returned a bare number, add context
    if (RegExp(r'^\d+([\.,]\d+)?$').hasMatch(out)) {
      out = 'Estimation: $out kcal (analyse IA)';
    }
    return out.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).popUntil((route) => route.isFirst);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.13),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.home_rounded,
                  color: AppColors.primaryColor,
                  size: 26,
                ),
              ),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    SizedBox(width: 38),
                    Icon(
                      Icons.image_search_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "🔍 VisionAI",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 23,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Analyse alimentaire par IA",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image preview
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _imageFile != null
                    ? Container(
                        key: const ValueKey('img'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryColor.withOpacity(0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(
                            _imageFile!,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        key: const ValueKey('icon'),
                        height: 180,
                        width: 180,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.image_search_rounded,
                          color: AppColors.primaryColor.withOpacity(0.22),
                          size: 90,
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              // Boutons
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.primaryColor)
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      label: const Text(
                        "Prendre une photo",
                        style: TextStyle(color: Colors.white, fontSize: 15.5),
                      ),
                      onPressed: () => _pickAndAnalyze(ImageSource.camera),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.primaryColor,
                        size: 22,
                      ),
                      label: const Text(
                        "Galerie",
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 15.5,
                        ),
                      ),
                      onPressed: () => _pickAndAnalyze(ImageSource.gallery),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Résultat IA
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _result.isEmpty
                          ? "📸 Prends une photo ou choisis-en une pour découvrir ce que tu manges !"
                          : _result,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.2,
                        color: _result.isEmpty
                            ? Colors.grey[600]
                            : AppColors.primaryColor,
                        fontWeight: _result.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                        fontStyle: _result.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        height: 1.5,
                        letterSpacing: 0.05,
                      ),
                    ),
                    if (_result.isNotEmpty && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "✨ Analyse IA Gemini",
                          style: TextStyle(
                            color: AppColors.accentColor,
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
