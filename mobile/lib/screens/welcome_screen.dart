import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_session_provider.dart';

/// Welcome/Home screen - entry point for scanning
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Title
                const Center(
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 80,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Form-Fitting Prints',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Custom wearables that fit you perfectly',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                // Guidance Section
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Before You Start',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGuidanceItem(
                        '📍',
                        'Find a well-lit area with good lighting',
                      ),
                      const SizedBox(height: 8),
                      _buildGuidanceItem(
                        '👕',
                        'Wear form-fitting clothes or underwear',
                      ),
                      const SizedBox(height: 8),
                      _buildGuidanceItem(
                        '📏',
                        'Stand 1.5m away from a plain background',
                      ),
                      const SizedBox(height: 8),
                      _buildGuidanceItem(
                        '⏱️',
                        'Scanning takes about 3-5 minutes',
                      ),
                    ],
                  ),
                ),

                // Start Button
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Start new session
                      context.read<ScanSessionProvider>().startNewSession();
                      
                      // Navigate to camera screen
                      Navigator.of(context).pushNamed('/camera');
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Scanning'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Optional: Settings/About links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('Settings'),
                    ),
                    const Text('•'),
                    TextButton(
                      onPressed: () {},
                      child: const Text('About'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidanceItem(String icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ],
    );
  }
}
