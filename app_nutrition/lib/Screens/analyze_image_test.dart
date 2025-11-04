// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../Services/image_ai_analysis_service.dart';
import 'package:flutter/foundation.dart';

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
    const primaryGreen = Color(0xFF4CAF50); // Vert menthe
    const lightGreen = Color(0xFFE8F5E9); // Vert très clair pour fond
    const darkGreen = Color(0xFF2E7D32); // Vert foncé pour accent

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, darkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_search_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "VisionAI",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          "Analyse d'image alimentaire",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w400,
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image preview
              if (_imageFile != null)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      _imageFile!,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.image_search_rounded,
                  color: darkGreen.withOpacity(0.5),
                  size: 150,
                ),

              const SizedBox(height: 25),

              // Boutons
              if (_isLoading)
                const CircularProgressIndicator(color: primaryGreen)
              else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Prendre une photo",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () => _pickAndAnalyze(ImageSource.camera),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryGreen, width: 1.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  icon: Icon(Icons.photo_library_rounded, color: darkGreen),
                  label: Text(
                    "Choisir depuis la galerie",
                    style: TextStyle(color: darkGreen, fontSize: 16),
                  ),
                  onPressed: () => _pickAndAnalyze(ImageSource.gallery),
                ),
              ],

              const SizedBox(height: 30),

              // Résultat IA
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.09),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
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
                        fontSize: 15.5,
                        color: _result.isEmpty ? Colors.grey[600] : darkGreen,
                        fontWeight: _result.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                        fontStyle: _result.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                        height: 1.45,
                        letterSpacing: 0.05,
                      ),
                    ),
                    if (_result.isNotEmpty && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          "✨ Analyse IA Gemini",
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12,
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
