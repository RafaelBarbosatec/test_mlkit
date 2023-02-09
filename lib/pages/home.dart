import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text('Start scan face'),
              onPressed: () {
                Navigator.pushNamed(context, '/face');
              },
            ),
            // ElevatedButton(
            //   child: const Text('Start scan document'),
            //   onPressed: () {
            //     Navigator.pushNamed(context, '/document');
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
