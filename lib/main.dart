import 'package:flutter/material.dart';
import 'package:wildpedia/pages/home.dart';
import 'package:wildpedia/services/storage.dart';

// TODO: create storage instance to get the document directory ahead of time
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    LocalStorage();
    return const MaterialApp(
      home: Home(),
    );
  }
}
