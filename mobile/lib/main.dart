import 'package:flutter/material.dart';

void main() {
  runApp(const FormFittingPrintsApp());
}

class FormFittingPrintsApp extends StatelessWidget {
  const FormFittingPrintsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form-Fitting Prints',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScanningHomePage(title: 'Body Scanner'),
    );
  }
}

class ScanningHomePage extends StatefulWidget {
  const ScanningHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<ScanningHomePage> createState() => _ScanningHomePageState();
}

class _ScanningHomePageState extends State<ScanningHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Form-Fitting Prints - Phase 1',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scanning pipeline (placeholder)',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera feature coming in Phase 1')),
                );
              },
              child: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
