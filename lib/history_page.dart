import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final List<String> history;

  const HistoryPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(history[index]),
          );
        },
      ),
    );
  }
}
