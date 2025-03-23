import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'screens/splash_screen.dart';

final logger = Logger();

/// Function to handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i('Handling a background message: ${message.messageId}');
}

/// Function to send push notifications
Future<void> sendPushNotification({required String title, required String body, required String topic}) async {
  FirebaseMessaging.instance.subscribeToTopic(topic); // Ensure subscription
  logger.i('📩 Push notification sent to $topic: $title - $body');
}

/// Function to subscribe to topics
void subscribeToTopics() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Subscribe to both topics
  await messaging.subscribeToTopic('high-water-level');
  await messaging.subscribeToTopic('early-warning');
  
  logger.i('✅ Subscribed to "high-water-level" and "early-warning" topics');
}

void monitorWaterLevel() {
  final supabase = Supabase.instance.client;
  DateTime? lastUpdateTime;
  double? lastWaterLevel; // Stores the previous water level

  supabase
      .from('water_levels')
      .stream(primaryKey: ['last_updated'])
      .order('last_updated', ascending: false)
      .listen((List<Map<String, dynamic>> event) async {
    logger.i('Stream event received: $event');

    if (event.isNotEmpty) {
      final latestRecord = event.first;
      final currentWaterLevel = latestRecord['water_level'];
      final currentUpdateTime = DateTime.tryParse(latestRecord['last_updated']);

      if (currentUpdateTime == null) {
        logger.e('Invalid timestamp in the record: ${latestRecord['last_updated']}');
        return;
      }

      if ((currentWaterLevel is int || currentWaterLevel is double) &&
          (lastUpdateTime == null || currentUpdateTime.isAfter(lastUpdateTime!))) {
        final waterLevel = double.parse(currentWaterLevel.toString());

        logger.i('New water level detected: ${waterLevel.toStringAsFixed(1)} meters at $currentUpdateTime');
        lastUpdateTime = currentUpdateTime;

        // Early Warning Alert
        if (lastWaterLevel != null && waterLevel > lastWaterLevel! && waterLevel < 3) {
          logger.i('🚨 Early Warning: Water level is rising to ${waterLevel.toStringAsFixed(1)} meters! Stay Alert!');
          
          await sendPushNotification(
            title: 'Early Warning Alert',
            body: 'Water level is rising to ${waterLevel.toStringAsFixed(1)} meters! Stay alert!',
            topic: 'early-warning',
          );
        }

        // High Water Level Alert
        if (waterLevel >= 3 && (lastWaterLevel == null || waterLevel > lastWaterLevel!)) {
          logger.i('⚠️ High Water Level Alert: The water level has risen to ${waterLevel.toStringAsFixed(1)} meters! Evacuate immediately!');

          await sendPushNotification(
            title: 'High Water Level Alert',
            body: 'The water level has risen to ${waterLevel.toStringAsFixed(1)} meters! Evacuate immediately!',
            topic: 'high-water-level',
          );
        }

        lastWaterLevel = waterLevel; // Update last recorded level
      }
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://efirubankmowqztlyuuh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmaXJ1YmFua21vd3F6dGx5dXVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgzMDc5NjAsImV4cCI6MjA1Mzg4Mzk2MH0.JmTTNz5AESMKQIwQl9t0qfU33EMLc5Z2-WePRGtaCog',
  );

  // Subscribe to notification topics
  subscribeToTopics();

  // Firebase Messaging handlers
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permissions for push notifications
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    logger.i('✅ User granted permission for notifications.');
  } else {
    logger.i('❌ User denied permission for notifications.');
  }

  // Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    logger.i('🔔 Foreground message received: ${message.notification?.title} - ${message.notification?.body}');
    
    if (message.notification != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification!.title ?? 'Notification'),
          content: Text(message.notification!.body ?? 'You have a new notification'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  });

  // Start monitoring water levels
  monitorWaterLevel();

  runApp(const MyApp());
}

// Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Assign navigator key
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}
