import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ARViewScreen extends StatelessWidget {
  final String arModelUrl;

  const ARViewScreen({super.key, required this.arModelUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AR View")),
      body: ModelViewer(
        src: arModelUrl, // Ensure the URL is passed correctly
        ar: true, // Enables AR feature
        arModes: [
          'scene-viewer',
          'webxr',
          'quick-look'
        ], // Support for Android/iOS
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }
}
