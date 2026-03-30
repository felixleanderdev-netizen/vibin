import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/scan_session_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/upload_summary_screen.dart';

void main() {
  runApp(const FormFittingPrintsApp());
}

class FormFittingPrintsApp extends StatelessWidget {
  const FormFittingPrintsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanSessionProvider()),
      ],
      child: MaterialApp(
        title: 'Form-Fitting Prints',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
          ),
        ),
        home: const WelcomeScreen(),
        routes: {
          '/camera': (context) => const CameraScreen(),
          '/upload_summary': (context) => const UploadSummaryScreen(),
        },
        onGenerateRoute: (settings) {
          // Fallback route
          return MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
