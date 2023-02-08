import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Start flow'),
          onPressed: () {
            Navigator.pushNamed(context, '/face');
          },
        ),
      ),
    );
  }
}
