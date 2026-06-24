import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../app_theme.dart';
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
              backgroundColor: GC.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Gato já capturado? 🤔', style: TextStyle(color: Colors.white)),
              content: Text(
                'Parece que você capturou um gato bem perto daqui antes (Gato #${nearby.entryNumber}). É o mesmo gato?',
                style: const TextStyle(color: GC.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar', style: TextStyle(color: GC.textMuted)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: GC.gold),
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
            _buildPurpleBorder(),
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
      return const Center(child: CircularProgressIndicator(color: GC.gold));
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildPurpleBorder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: GC.gold, width: 2.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: GC.gold.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
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
            _buildHeartsCounter(),
            const SizedBox(height: 8),
            _buildTimingBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GC.bgDeep.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GC.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _maxTries; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Text(
              i < _triesLeft ? '❤️' : '🖤',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimingBar() {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: GC.bgDeep.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: GC.purple.withValues(alpha: 0.4)),
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
                  // Track
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: GC.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Success zone
                  Positioned(
                    left: ((_dotPosition - _successZone) * width).clamp(0, width),
                    width: _successZone * 2 * width,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: GC.gold.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Fixed dot (target) — paw print emoji
                  Positioned(
                    left: dotX - 8,
                    top: -5,
                    child: const Text('🐾', style: TextStyle(fontSize: 14)),
                  ),
                  // Moving bar indicator
                  Positioned(
                    left: barX - 2,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: GC.gold,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(color: GC.gold.withValues(alpha: 0.6), blurRadius: 6),
                        ],
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
      left: 24,
      right: 24,
      child: Column(
        children: [
          if (_resultMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: GC.bgDeep.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GC.purple.withValues(alpha: 0.4)),
              ),
              child: Text(
                _resultMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [GC.purple.withValues(alpha: 0.9), GC.bgElevated.withValues(alpha: 0.9)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: GC.gold.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✨', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'Toque quando a barra estiver no ponto!',
                  style: TextStyle(
                    color: GC.goldLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 6),
                Text('✨', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    final isSuccess = _resultMessage?.contains('Capturado') ?? false;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GC.bgDeep.withValues(alpha: 0.9),
            GC.bgElevated.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess ? '🎉' : '😿',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 12),
            if (isSuccess) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐', style: TextStyle(fontSize: 20, color: GC.gold.withValues(alpha: 0.8))),
                  const SizedBox(width: 6),
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('⭐', style: TextStyle(fontSize: 20, color: GC.gold.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
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
            const SizedBox(height: 36),
            if (isSuccess)
              _GoldResultButton(
                label: 'Ver Gatodex ✨',
                onPressed: () => Navigator.pop(context, true),
              )
            else
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GC.textMuted,
                  side: BorderSide(color: GC.purple.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar'),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoldResultButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GoldResultButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GC.gold, Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: GC.gold.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 5)),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: const Color(0xFF1A0050),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
