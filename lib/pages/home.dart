import 'package:flutter/material.dart';
import 'scan.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(156, 156, 156, 1),
      appBar: AppBar(
        title: const Center(child: Text('Pay & Go')),
        backgroundColor: const Color.fromRGBO(77, 203, 239, 1),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Scan()),
            );
          },
          child: const Text(
            'Scan',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
