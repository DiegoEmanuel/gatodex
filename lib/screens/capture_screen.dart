import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/cat_entry.dart';
import '../services/database_service.dart';
import '../widgets/name_cat_sheet.dart';

class CaptureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CaptureScreen({super.key, required this.cameras});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;

  late AnimationController _barController;
  late Animation<double> _barAnimation;

  static const int _maxTries = 3;
  int _triesLeft = _maxTries;
  bool _isProcessing = false;
  bool _gameOver = false;
  String? _resultMessage;

  // The dot is fixed at 30% of the bar width; success zone ±8%
  static const double _dotPosition = 0.30;
  static const double _successZone = 0.08;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initBarAnimation();
  }

  void _initBarAnimation() {
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_isProcessing || _gameOver) return;

    final barValue = _barAnimation.value;
    final hit = (barValue - _dotPosition).abs() <= _successZone;

    if (hit) {
      setState(() => _isProcessing = true);
      _barController.stop();
      await _captureAndSave();
    } else {
      setState(() {
        _triesLeft--;
        if (_triesLeft <= 0) {
          _gameOver = true;
          _barController.stop();
          _resultMessage = 'O gato fugiu! 😿';
        } else {
          _resultMessage = 'Errou! $_triesLeft tentativa${_triesLeft == 1 ? '' : 's'} restante${_triesLeft == 1 ? '' : 's'}';
        }
      });
    }
  }

  Future<void> _captureAndSave() async {
    try {
      final photo = await _cameraController!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final filename = 'cat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(dir.path, filename);
      await File(photo.path).copy(savedPath);

      Position? position;
      try {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        position = null;
      }

      // Checagem de duplicata: avisa se já tem captura a menos de 50m
      if (position != null && mounted) {
        final nearby = await DatabaseService().findNearby(
          position.latitude,
          position.longitude,
          radiusMeters: 50,
        );
        if (nearby != null && mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              title: const Text('Gato já capturado?', style: TextStyle(color: Colors.white)),
              content: Text(
                'Parece que você capturou um gato bem perto daqui antes (Gato #${nearby.entryNumber}). É o mesmo gato?',
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8C00)),
                  child: const Text('Capturar mesmo assim'),
                ),
              ],
            ),
          );
          if (proceed != true) {
            if (mounted) {
              setState(() {
                _isProcessing = false;
                _triesLeft = _maxTries;
                _resultMessage = null;
              });
              _barController.repeat(reverse: true);
            }
            return;
          }
        }
      }

      final count = await DatabaseService().count();
      final entry = CatEntry(
        imagePath: savedPath,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        capturedAt: DateTime.now(),
        entryNumber: count + 1,
      );
      final saved = await DatabaseService().insert(entry);

      if (mounted) {
        final name = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => NameCatSheet(
            catId: saved.id!,
            entryNumber: saved.entryNumber,
          ),
        );
        if (mounted) {
          setState(() {
            _gameOver = true;
            _resultMessage = name != null
                ? '$name capturado! 🎉 Gato #${saved.entryNumber} na Gatodex!'
                : 'Capturado! 🎉 Gato #${saved.entryNumber} na Gatodex!';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _resultMessage = 'Erro ao salvar. Tente novamente.';
        });
        _barController.repeat(reverse: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraPreview(),
            _buildOrangeBorder(),
            _buildTopHUD(),
            if (_gameOver) _buildResultOverlay(),
            if (!_gameOver) _buildHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildOrangeBorder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFF8C00), width: 3),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTriesCounter(),
            const SizedBox(height: 8),
            _buildTimingBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTriesCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐾', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$_triesLeft / $_maxTries tries',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingBar() {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedBuilder(
        animation: _barAnimation,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final barX = _barAnimation.value * width;
              final dotX = _dotPosition * width;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // track
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // success zone highlight
                  Positioned(
                    left: ((_dotPosition - _successZone) * width).clamp(0, width),
                    width: _successZone * 2 * width,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // fixed dot (target)
                  Positioned(
                    left: dotX - 6,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8C00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // moving bar indicator
                  Positioned(
                    left: barX - 2,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHint() {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Column(
        children: [
          if (_resultMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _resultMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C00).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Toque quando a barra estiver no ponto!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final isSuccess = _resultMessage?.contains('Capturado') ?? false;
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess ? '🎉' : '😿',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _resultMessage ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.pop(context, isSuccess),
              child: Text(isSuccess ? 'Ver Gatodex' : 'Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
