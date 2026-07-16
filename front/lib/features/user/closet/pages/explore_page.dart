import 'package:flutter/material.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('탐색')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('탐색 준비 중',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
