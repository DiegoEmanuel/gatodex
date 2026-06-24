import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Garante um perfil guest (anônimo) para ter um UID estável no Storage.
  // Falha de rede aqui não deve travar o app — o upload é não-crítico.
  try {
    await AuthService().ensureSignedIn();
  } catch (e, s) {
    FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
  }

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
      theme: gatodexTheme(),
      home: HomeScreen(cameras: cameras),
    );
  }
}
