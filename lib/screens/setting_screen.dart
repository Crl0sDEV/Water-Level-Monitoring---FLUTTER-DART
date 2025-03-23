import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 28, 112, 244),
      ),
      body: Center(
        child: const Text(
          'This is the Settings Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
