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
        src: "assets/3d_models/t1_helmet.glb",
        ar: true, // Enables AR feature
        arModes: ['scene-viewer', 'webxr', 'quick-look'], // Support for Android/iOS
        autoRotate: true,
        cameraControls: true,
      ),
    );
  }
}


// // ignore_for_file: library_private_types_in_public_api

// import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
// import 'package:flutter/material.dart';
// import 'package:vector_math/vector_math_64.dart' as vector;

// class ARViewScreen extends StatefulWidget {
//   final String arModelUrl;
//   const ARViewScreen({super.key, required this.arModelUrl});

//   @override
//   _ARViewScreenState createState() => _ARViewScreenState();
// }

// class _ARViewScreenState extends State<ARViewScreen> {
//   ArCoreController? arCoreController;
//   bool isDisposed = false; // Prevents duplicate disposal

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AR View'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: _onBackPressed,
//         ),
//       ),
//       body: WillPopScope(
//         onWillPop: () async {
//           _onBackPressed();
//           return false; // Prevents default back behavior
//         },
//         child: ArCoreView(
//           onArCoreViewCreated: _onArCoreViewCreated,
//         ),
//       ),
//     );
//   }

//   void _onArCoreViewCreated(ArCoreController controller) {
//     if (!mounted) return;

//     setState(() {
//       arCoreController = controller;
//     });

//     _load3DModel(controller);
//   }

//   void _load3DModel(ArCoreController controller) {
//     final node = ArCoreReferenceNode(
//       name: "3DModel",
//       objectUrl: widget.arModelUrl, // Load AR model dynamically
//       position: vector.Vector3(0, 0, -2.0), // Adjust position as needed
//       scale: vector.Vector3(0.5, 0.5, 0.5), // Adjust scale as needed
//     );

//     controller.addArCoreNode(node);
//   }

//   void _onBackPressed() async {
//     if (isDisposed) return;
//     isDisposed = true;

//     try {
//       arCoreController?.dispose();
//     } catch (e) {
//       debugPrint("Error disposing ARCoreController: $e");
//     }

//     if (mounted) {
//       Navigator.pop(context);
//     }
//   }

//   @override
//   void dispose() {
//     if (!isDisposed) {
//       try {
//         arCoreController?.dispose();
//       } catch (e) {
//         debugPrint("Error disposing ARCoreController: $e");
//       }
//       isDisposed = true;
//     }
//     super.dispose();
//   }
// }

// import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
// import 'package:ar_flutter_plugin/datatypes/node_types.dart';
// import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
// import 'package:ar_flutter_plugin/models/ar_node.dart';
// import 'package:flutter/material.dart';
// import 'package:vector_math/vector_math_64.dart';

// class ARViewScreen extends StatefulWidget {
//   final String arModelUrl;

//   const ARViewScreen({super.key, required this.arModelUrl});

//   @override
//   _ARViewScreenState createState() => _ARViewScreenState();
// }

// class _ARViewScreenState extends State<ARViewScreen> {
//   late ARSessionManager arSessionManager;
//   late ARObjectManager arObjectManager;
//   ARNode? localObjectNode;
//   bool isAdd = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("AR View")),
//       body: ARView(
//         onARViewCreated: _onARViewCreated,
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: onLocalObjectButtonPressed,
//         child: Icon(isAdd ? Icons.remove : Icons.add),
//       ),
//     );
//   }

//   void _onARViewCreated(
//       ARSessionManager arSessionManager,
//       ARObjectManager arObjectManager,
//       ARAnchorManager arAnchorManager,
//       ARLocationManager arLocationManager) {
//     this.arSessionManager = arSessionManager;
//     this.arObjectManager = arObjectManager;

//     // plane visualization (hand gesture)
//     // this.arSessionManager.onInitialize(
//     //       showFeaturePoints: false,
//     //       showPlanes: true,
//     //       customPlaneTexturePath: "assets/triangle.png",
//     //       showWorldOrigin: true,
//     //       handleTaps: false,
//     //     );

//     this.arObjectManager.onInitialize();
//   }

//   Future onLocalObjectButtonPressed() async {
//     if (localObjectNode != null) {
//       arObjectManager.removeNode(localObjectNode!);
//       localObjectNode = null;
//     } else {
//       var newNode = ARNode(
//           type: NodeType.localGLTF2,
//           // uri: "assets/3d_models/Chicken_01/Chicken_01.gltf",
//           uri: "assets/3d_models/t1_helmet/result.gltf",
//           scale: Vector3(0.2, 0.2, 0.2),
//           position: Vector3(0.0, 0.0, 0.0),
//           rotation: Vector4(1.0, 0.0, 0.0, 0.0));
//       bool? didAddLocalNode = await arObjectManager.addNode(newNode);
//       localObjectNode = (didAddLocalNode!) ? newNode : null;
//     }
//   }

//   @override
//   void dispose() {
//     arSessionManager.dispose();
//     super.dispose();
//   }
// }
