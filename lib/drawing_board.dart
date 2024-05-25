import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class DrawingBoard extends StatefulWidget {
  const DrawingBoard({super.key});

  @override
  DrawingBoardState createState() => DrawingBoardState();
}

class DrawingBoardState extends State<DrawingBoard> {
  final List<DrawnLine> _lines = [];

  double _strokeWidth = 5.0;

  Color _selectedColor = Colors.black;

  DrawnLine? _currentLine;

  final GlobalKey _globalKey = GlobalKey();

  List<Color> colors = const [
    Colors.red,
    Colors.pink,
    Colors.yellow,
    Colors.purple,
    Colors.green,
    Colors.blue,
    Colors.blueGrey,
    Colors.teal,
    Colors.orange,
    Colors.brown,
    Colors.lime,
    Colors.indigo,
    Colors.cyan,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveToFile();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brush),
            onPressed: () => _showStrokeWidthPicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: () => _showColorPicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => _undoLastLine(),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _lines.clear()),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: LayoutBuilder(builder: (context, constraints) {
          return GestureDetector(
            onPanStart: (details) {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              Offset point = renderBox.globalToLocal(details.globalPosition);
              setState(() {
                _currentLine = DrawnLine(
                  [point],
                  _selectedColor,
                  _strokeWidth,
                );
                _lines.add(_currentLine!);
              });
            },
            onPanUpdate: (details) {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              Offset point = renderBox.globalToLocal(details.globalPosition);
              setState(() {
                _currentLine!.points.add(point);
              });
            },
            onPanEnd: (details) {
              _currentLine = null;
            },
            child: CustomPaint(
              painter: Sketcher(_lines),
              size: Size.infinite,
            ),
          );
        }),
      ),
    );
  }

  void _showStrokeWidthPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        double tempStrokeWidth = _strokeWidth;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pinsel auswählen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempStrokeWidth,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: tempStrokeWidth.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        tempStrokeWidth = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Fertig'),
                  onPressed: () {
                    setState(() {
                      _strokeWidth = tempStrokeWidth;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe auswählen'),
        content: Wrap(
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
                Navigator.of(context).pop();
              },
              child: Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                width: 30,
                height: 30,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _undoLastLine() {
    setState(() {
      if (_lines.isNotEmpty) {
        _lines.removeLast();
      }
    });
  }

  Future<void> _saveToFile() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      //temp
      String base64String = base64Encode(pngBytes);

      // Füge den MIME-Typ hinzu
      String dataUri = 'data:image/png;base64,$base64String';

      // Teile den Base64-String in Teile auf und drucke sie nacheinander
      const int chunkSize = 1024;
      for (var i = 0; i < dataUri.length; i += chunkSize) {
        print(dataUri.substring(i,
            i + chunkSize > dataUri.length ? dataUri.length : i + chunkSize));
      }
    } catch (e) {
      print('Error saving image: $e');
    }
  }
}

class DrawnLine {
  List<Offset> points;
  Color color;
  double strokeWidth;

  DrawnLine(this.points, this.color, this.strokeWidth);
}

class Sketcher extends CustomPainter {
  final List<DrawnLine> lines;

  Sketcher(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (var line in lines) {
      Paint paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = line.strokeWidth;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(Sketcher oldDelegate) => true;
}
