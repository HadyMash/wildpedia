import 'package:flutter/material.dart';

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        // leading: IconButton(
        //   icon: const Icon(Icons.close),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      // TODO: get history from storage and load it in
    );
  }
}
