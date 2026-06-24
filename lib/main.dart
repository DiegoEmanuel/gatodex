import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
