import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ARViewScreen extends StatefulWidget {
  final String arModelUrl;
  final List<String> colors; // Add colors as a parameter
  const ARViewScreen(
      {super.key, required this.arModelUrl, required this.colors});

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  late WebViewController _controller;
  String? selectedColor; // Selected color from the dropdown
  late Map<String, Color>
      colorMap; // Map of color names to actual Color objects

  @override
  void initState() {
    super.initState();
    _initializeColorMap();
  }

  void _initializeColorMap() {
    // Map product colors to Flutter colors (fallback to black if not found)
    colorMap = {
      for (var color in widget.colors)
        color: _getColorFromName(color) ?? Colors.black,
    };
  }

  Color? _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'brown':
        return Colors.brown;
      case 'cyan':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'amber':
        return Colors.amber;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'light blue':
        return Colors.lightBlue;
      case 'light green':
        return Colors.lightGreen;
      case 'deep orange':
        return Colors.deepOrange;
      case 'deep purple':
        return Colors.deepPurple;
      case 'gold':
      case 'metallic gold':
        return Colors.amberAccent; // Use a predefined Flutter color
      case 'silver':
        return Colors.blueGrey; // Closest predefined color for silver
      case 'beige':
        return Colors.brown[100]!; // Use a shade of brown
      case 'maroon':
        return Colors.red[900]!; // Use a dark shade of red
      case 'olive':
        return Colors.green[800]!; // Use a dark shade of green
      case 'navy':
        return Colors.blue[900]!; // Use a dark shade of blue
      case 'turquoise':
        return Colors.cyan[400]!; // Use a light shade of cyan
      case 'goldenrod':
        return Colors.amber; // Use amber for goldenrod
      case 'khaki':
        return Colors.yellow[200]!; // Use a light shade of yellow
      case 'coral':
        return Colors.deepOrange[200]!; // Use a light shade of deep orange
      case 'salmon':
        return Colors.pink[200]!; // Use a light shade of pink
      case 'chocolate':
        return Colors.brown[600]!; // Use a dark shade of brown
      case 'plum':
        return Colors.purple[200]!; // Use a light shade of purple
      case 'orchid':
        return Colors.purple[300]!; // Use a medium shade of purple
      case 'lavender':
        return Colors.purple[100]!; // Use a very light shade of purple
      case 'peach':
        return Colors.orange[200]!; // Use a light shade of orange
      case 'mint':
        return Colors.green[200]!; // Use a light shade of green
      case 'mustard':
        return Colors.yellow[700]!; // Use a dark shade of yellow
      case 'charcoal':
        return Colors.grey[800]!; // Use a dark shade of grey
      case 'ivory':
        return Colors.grey[50]!; // Use a very light shade of grey
      case 'sand':
        return Colors.brown[300]!; // Use a medium shade of brown
      case 'rose':
        return Colors.pink[400]!; // Use a medium shade of pink
      case 'wine':
        return Colors.red[800]!; // Use a dark shade of red
      case 'emerald':
        return Colors.green[600]!; // Use a medium shade of green
      case 'jade':
        return Colors.green[700]!; // Use a dark shade of green
      case 'sapphire':
        return Colors.blue[800]!; // Use a dark shade of blue
      case 'ruby':
        return Colors.red[700]!; // Use a dark shade of red
      case 'amethyst':
        return Colors.purple[700]!; // Use a dark shade of purple
      default:
        return null; // Return null if the color is not recognized
    }
  }

  Future<String> _loadHtmlWithModelUrl() async {
    final rawHtml = await rootBundle.loadString('assets/ar_customizer.html');
    final replacedHtml = rawHtml.replaceAll('%MODEL_URL%', widget.arModelUrl);
    print("✅ HTML Injected:\n$replacedHtml"); // Add this line
    return replacedHtml;
  }

  void _applyColor(Color color) {
    final r = (color.red / 255).toStringAsFixed(2);
    final g = (color.green / 255).toStringAsFixed(2);
    final b = (color.blue / 255).toStringAsFixed(2);
    _controller.runJavaScript('setColor($r, $g, $b);');
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select a color'),
        content: DropdownButtonFormField<String>(
          value: selectedColor,
          items: colorMap.keys.map((colorName) {
            return DropdownMenuItem(
              value: colorName,
              child: Text(colorName),
            );
          }).toList(),
          onChanged: (colorName) {
            setState(() {
              selectedColor = colorName;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Available Colors',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Apply'),
            onPressed: () {
              if (selectedColor != null) {
                _applyColor(colorMap[selectedColor!]!);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadHtmlWithModelUrl(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('AR View')),
          body: WebViewWidget(
            controller: _controller = WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..setNavigationDelegate(NavigationDelegate(
                onNavigationRequest: (request) {
                  if (request.url.startsWith("intent://")) {
                    final fallbackUrl =
                        request.url.replaceFirst("intent://", "https://");
                    launchUrl(Uri.parse(fallbackUrl),
                        mode: LaunchMode.externalApplication);
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ))
              ..loadHtmlString(snapshot.data!),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.colors
                  .isNotEmpty) // Show color picker only if colors are available
                FloatingActionButton(
                  heroTag: 'colorPickerButton', // Unique heroTag
                  onPressed: _showColorPicker,
                  child: const Icon(Icons.color_lens),
                ),
              if (widget.colors.isNotEmpty)
                const SizedBox(
                    height: 16), // Add spacing if color picker exists
              FloatingActionButton(
                heroTag: 'viewInARButton', // Unique heroTag
                onPressed: () {
                  _controller.runJavaScript(
                      'document.querySelector("#model").activateAR();');
                },
                child: const Icon(Icons.view_in_ar),
              ),
            ],
          ),
        );
      },
    );
  }
}
