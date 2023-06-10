import 'package:flutter/material.dart';
import 'package:wildpedia/pages/home.dart';

// TODO: create storage instance to get the document directory ahead of time
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}
