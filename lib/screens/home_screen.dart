import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cat_entry.dart';
import '../services/database_service.dart';
import 'capture_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CatEntry> _cats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    final cats = await DatabaseService().getAll();
    if (mounted) setState(() { _cats = cats; _loading = false; });
  }

  Future<void> _openCapture() async {
    final captured = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(cameras: widget.cameras),
      ),
    );
    if (captured == true) _loadCats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Text('🐾', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Gatodex',
              style: TextStyle(
                color: Color(0xFFFF8C00),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Text('🗺️', style: TextStyle(fontSize: 20)),
            tooltip: 'Mapa',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_cats.length} capturado${_cats.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
          : _cats.isEmpty
              ? _buildEmpty()
              : _buildGrid(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCapture,
        backgroundColor: const Color(0xFFFF8C00),
        icon: const Text('📷', style: TextStyle(fontSize: 20)),
        label: const Text(
          'Capturar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🐈', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          const Text(
            'Sua Gatodex está vazia!',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encontre um gato e toque em Capturar.',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capturar primeiro gato'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _cats.length,
      itemBuilder: (_, i) => _CatCard(cat: _cats[i]),
    );
  }
}

class _CatCard extends StatelessWidget {
  final CatEntry cat;
  const _CatCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yy').format(cat.capturedAt);
    final hasLocation = cat.latitude != 0.0 || cat.longitude != 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8C00).withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(cat.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF0F3460),
                      child: Center(child: Text('🐈', style: TextStyle(fontSize: 40))),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '#${cat.entryNumber.toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name ?? 'Gato #${cat.entryNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cat.name != null)
                    Text(
                      '#${cat.entryNumber.toString().padLeft(3, '0')}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(date, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const Spacer(),
                      Text(
                        hasLocation ? '📍' : '📍?',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasLocation ? Colors.greenAccent : Colors.white30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
