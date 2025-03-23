import 'package:flutter/material.dart';
import 'package:emailjs/emailjs.dart' as emailjs;
import 'package:logger/logger.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();
  final Logger _logger = Logger();

  bool isSending = false;

  // Helper function to show a Snackbar message
  void showSnackBarMessage(String message, Color backgroundColor, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> sendFeedback(String name, String feedback) async {
  setState(() => isSending = true);

  try {
    await emailjs.send(
      'service_3b4tp6i',
      'template_cit1l7d',
      {
        'to_name': 'Admin',
        'user_name': name,
        'user_feedback': feedback,
      },
      emailjs.Options(
        publicKey: 'MVoRIG6I2wdOc8KjM',
        privateKey: 't61OPP8cW0HQG0yT4CFAq',
      ),
    );

    showSnackBarMessage('Feedback sent successfully!', Colors.green, Icons.check_circle);

    nameController.clear();
    feedbackController.clear();
  } catch (e) {
    showSnackBarMessage('Failed to send feedback: ${e.toString()}', Colors.red, Icons.error);
    _logger.e('EmailJS Error: $e');
  } finally {
    setState(() => isSending = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'We value your feedback!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Let us know your thoughts to help us improve.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: feedbackController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Your Feedback',
                        prefixIcon: const Icon(Icons.feedback),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSending
                            ? null
                            : () {
                                final String name = nameController.text.trim();
                                final String feedback = feedbackController.text.trim();

                                if (name.isEmpty || feedback.isEmpty) {
                                  showSnackBarMessage(
                                    'Please fill in all fields before submitting.',
                                    Colors.orange,
                                    Icons.warning,
                                  );
                                } else {
                                  sendFeedback(name, feedback);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSending
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
