import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() {
  runApp(const SnackyTestApp());
}

class SnackyTestApp extends StatelessWidget {
  const SnackyTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Snacky3DPreview(),
    );
  }
}

class Snacky3DPreview extends StatelessWidget {
  const Snacky3DPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Snacky 3D 🍊"),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: const Center(
        child: ModelViewer(
          src: 'assets/3d/snacky.glb',
          alt: "Snacky 3D Model",
          autoRotate: true,
          cameraControls: true,
          backgroundColor: Colors.white,
          disableZoom: false,
        ),
      ),
    );
  }
}
