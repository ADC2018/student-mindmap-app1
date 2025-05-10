import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

class MindMapPage extends StatefulWidget {
  final List<XFile> images;
  MindMapPage({required this.images});

  @override
  _MindMapPageState createState() => _MindMapPageState();
}

class _MindMapPageState extends State<MindMapPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  late List<TextEditingController> _controllers;
  final Graph graph = Graph();
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.images.length, (index) => TextEditingController());
    _initGraph();
  }

  void _initGraph() {
    graph.nodes.clear();
    graph.edges.clear();
    List<Node> nodes = widget.images.map((img) => Node.Id(img.path)).toList();
    for (var node in nodes) {
      graph.addNode(node);
    }
    // 自动连线：第一个为中心，其余为分支
    for (int i = 1; i < nodes.length; i++) {
      graph.addEdge(nodes[0], nodes[i]);
    }
    builder
      ..siblingSeparation = (32)
      ..levelSeparation = (48)
      ..subtreeSeparation = (32)
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  Future<void> _saveMindMap() async {
    Uint8List? image = await screenshotController.capture();
    if (image != null) {
      final directory = await getExternalStorageDirectory();
      String path = directory!.path + '/思维导图_${DateTime.now().millisecondsSinceEpoch}.png';
      File file = File(path);
      await file.writeAsBytes(image);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('思维导图已保存到本地: $path')),
      );
    }
  }

  Widget _buildNode(String path, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: 80,
          child: TextField(
            controller: _controllers[index],
            decoration: InputDecoration(
              hintText: '输入重点',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            ),
            style: TextStyle(fontSize: 12),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('思维导图'),
        actions: [
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: _saveMindMap,
            tooltip: '保存到本地',
          ),
        ],
      ),
      body: Screenshot(
        controller: screenshotController,
        child: InteractiveViewer(
          constrained: false,
          boundaryMargin: EdgeInsets.all(100),
          minScale: 0.01,
          maxScale: 5.0,
          child: GraphView(
            graph: graph,
            algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
            builder: (Node node) {
              int idx = widget.images.indexWhere((img) => img.path == node.key!.value);
              return _buildNode(node.key!.value as String, idx);
            },
          ),
        ),
      ),
    );
  }
} 