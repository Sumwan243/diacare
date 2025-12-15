import 'package:flutter/material.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Assistant'),
      ),
      body: const Center(
        child: Text('AI Assistant Screen'),
      ),
    );
  }
}
