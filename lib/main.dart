import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  final cameras = await availableCameras();
  runApp(GatodexApp(cameras: cameras));
}

class GatodexApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const GatodexApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gatodex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF8C00),
          surface: const Color(0xFF1A1A2E),
        ),
      ),
      home: HomeScreen(cameras: cameras),
    );
  }
}
