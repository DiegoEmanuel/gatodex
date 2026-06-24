import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
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
      backgroundColor: GC.bgDeep,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBgDecor(),
          _loading
              ? const Center(child: CircularProgressIndicator(color: GC.gold))
              : _cats.isEmpty
                  ? _buildEmpty()
                  : _buildGrid(),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GC.bgDeep,
      title: Row(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'GATODEX',
                style: TextStyle(
                  color: GC.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 2,
                  height: 1.1,
                ),
              ),
              const Text(
                'Transforme, Colecione, Ame!',
                style: TextStyle(
                  color: GC.textMuted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Text('🗺️', style: TextStyle(fontSize: 20)),
          tooltip: 'Mapa de gatos',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          ),
        ),
        if (!_loading)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GC.purple.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GC.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_cats.length}',
                  style: const TextStyle(
                    color: GC.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 3),
                const Text('🐱', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                GC.gold.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBgDecor() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -20, right: -20,
            child: Text('✨', style: TextStyle(fontSize: 80, color: GC.gold.withValues(alpha: 0.04))),
          ),
          Positioned(
            bottom: 120, left: -10,
            child: Text('🐾', style: TextStyle(fontSize: 100, color: GC.purple.withValues(alpha: 0.08))),
          ),
          Positioned(
            top: 180, right: 10,
            child: Text('⭐', style: TextStyle(fontSize: 50, color: GC.gold.withValues(alpha: 0.05))),
          ),
          Positioned(
            bottom: 200, right: -15,
            child: Text('✨', style: TextStyle(fontSize: 60, color: GC.purple.withValues(alpha: 0.07))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('✨', style: TextStyle(fontSize: 28, color: GC.gold.withValues(alpha: 0.6))),
              const SizedBox(width: 4),
              const Text('🐱', style: TextStyle(fontSize: 80)),
              const SizedBox(width: 4),
              Text('✨', style: TextStyle(fontSize: 28, color: GC.gold.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Sua Gatodex está vazia!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Encontre um gato e toque em Capturar.',
            style: TextStyle(color: GC.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 36),
          _GoldButton(
            onPressed: _openCapture,
            icon: '📷',
            label: 'Capturar primeiro gato',
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: _cats.length,
      itemBuilder: (_, i) => _CatCard(cat: _cats[i], onDelete: _loadCats),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GC.gold, Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: GC.gold.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _openCapture,
        backgroundColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        icon: const Text('📷', style: TextStyle(fontSize: 20)),
        label: const Text(
          'Capturar',
          style: TextStyle(
            color: Color(0xFF1A0050),
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String icon;
  final String label;

  const _GoldButton({required this.onPressed, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GC.gold, Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: GC.gold.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: const Color(0xFF1A0050),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        icon: Text(icon, style: const TextStyle(fontSize: 18)),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  final CatEntry cat;
  final VoidCallback onDelete;
  const _CatCard({required this.cat, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yy').format(cat.capturedAt);
    final hasLocation = cat.latitude != 0.0 || cat.longitude != 0.0;

    return GestureDetector(
      onLongPress: () => _confirmDelete(context),
      child: _buildCard(date, hasLocation),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GC.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir gato? 🗑️', style: TextStyle(color: Colors.white)),
        content: Text(
          'Tem certeza que quer remover ${cat.name ?? 'Gato #${cat.entryNumber}'} da sua Gatodex? Essa ação não pode ser desfeita.',
          style: const TextStyle(color: GC.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: GC.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService().delete(cat.id!, cat.imagePath);
      onDelete();
    }
  }

  Widget _buildCard(String date, bool hasLocation) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1565), GC.bgCard],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: GC.gold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: GC.purple.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                      color: GC.bgElevated,
                      child: Center(child: Text('🐈', style: TextStyle(fontSize: 40))),
                    ),
                  ),
                  // Bottom fade overlay
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            GC.bgCard.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Gold number badge
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GC.gold,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: GC.gold.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '#${cat.entryNumber.toString().padLeft(3, '0')}',
                        style: const TextStyle(
                          color: Color(0xFF1A0050),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      Text(
                        date,
                        style: const TextStyle(color: GC.textMuted, fontSize: 10),
                      ),
                      const Spacer(),
                      Text(
                        hasLocation ? '📍' : '❓',
                        style: TextStyle(
                          fontSize: 11,
                          color: hasLocation ? GC.pink : Colors.white24,
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
