import 'package:flutter/material.dart';
import 'package:sketcher/drawing_board.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sketcher',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DrawingBoard(),
    );
  }
}
