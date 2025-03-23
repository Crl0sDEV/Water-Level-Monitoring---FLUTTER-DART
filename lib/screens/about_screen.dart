import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Info Section
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About This App',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'The Water Level Monitoring System is a smart flood detection tool designed to monitor and analyze real-time water levels at Polangui River. '
                      'Using an ultrasonic sensor and data analytics, the system provides accurate water level measurements, which are classified into Moderate, High, and Critical levels. '
                      'Users can access this information through a web dashboard for MDRRMO officials and a mobile application for residents. '
                      'The system also sends instant alerts during high-risk situations, ensuring early warning and disaster preparedness. '
                      'With real-time updates and an easy-to-use interface, this application helps keep the community informed and safe from potential flooding.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}