import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../app_theme.dart';
import '../models/cat_entry.dart';
import '../services/database_service.dart';
import 'capture_screen.dart';
import 'cat_detail_screen.dart';
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
      MaterialPageRoute(builder: (_) => CaptureScreen(cameras: widget.cameras)),
    );
    if (captured == true) _loadCats();
  }

  Future<void> _shareGallery() async {
    if (_cats.isEmpty) return;
    final lines = _cats.map((c) {
      final name = c.name != null ? ' — ${c.name}' : '';
      return '🐱 #${c.entryNumber.toString().padLeft(3, '0')}$name';
    }).join('\n');
    await Share.share(
      '🐾 Minha Gatodex tem ${_cats.length} gato${_cats.length == 1 ? '' : 's'}!\n\n$lines\n\n✨ Transforme, Colecione, Ame!\nBaixe o Gatodex e capture os gatos do seu bairro.',
      subject: 'Minha Gatodex 🐾',
    );
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
      titleSpacing: 16,
      title: Row(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('GATODEX', style: gfDisplay(22, c: GC.gold)),
              Text(
                'Transforme, Colecione, Ame!',
                style: gfBody(9, w: FontWeight.w600, c: GC.textMuted),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (!_loading && _cats.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            color: GC.textMuted,
            tooltip: 'Compartilhar coleção',
            onPressed: _shareGallery,
          ),
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
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GC.purple.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GC.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_cats.length}', style: gfDisplay(13, c: GC.gold)),
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
            gradient: LinearGradient(colors: [
              Colors.transparent,
              GC.gold.withValues(alpha: 0.3),
              Colors.transparent,
            ]),
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
          Text('Sua Gatodex está vazia!', style: gfDisplay(20, c: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Encontre um gato e toque em Capturar.',
            style: gfBody(14, c: GC.textMuted),
          ),
          const SizedBox(height: 36),
          _GoldButton(onPressed: _openCapture, icon: '📷', label: 'Capturar primeiro gato'),
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
      itemBuilder: (_, i) => _CatCard(cat: _cats[i], onReload: _loadCats),
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
          BoxShadow(color: GC.gold.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 5)),
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
        label: Text('Capturar', style: gfDisplay(15, c: GC.deepPurple)),
      ),
    );
  }
}

// ── Botão dourado reutilizável ─────────────────────────────────────────────
class _GoldButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String icon;
  final String label;

  const _GoldButton({required this.onPressed, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [GC.gold, Color(0xFFFFB300)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: GC.gold.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: GC.deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        icon: Text(icon, style: const TextStyle(fontSize: 18)),
        label: Text(label, style: gfDisplay(15, c: GC.deepPurple)),
      ),
    );
  }
}

// ── Card do gato ──────────────────────────────────────────────────────────
class _CatCard extends StatelessWidget {
  final CatEntry cat;
  final VoidCallback onReload;
  const _CatCard({required this.cat, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yy').format(cat.capturedAt);
    final hasLocation = cat.latitude != 0.0 || cat.longitude != 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatDetailScreen(cat: cat, onReload: onReload),
        ),
      ),
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1565), GC.bgCard],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GC.gold.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: GC.purple.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
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
                    // fade bottom
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, GC.bgCard.withValues(alpha: 0.9)],
                          ),
                        ),
                      ),
                    ),
                    // badge dourado
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GC.gold,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: GC.gold.withValues(alpha: 0.5), blurRadius: 6)],
                        ),
                        child: Text(
                          '#${cat.entryNumber.toString().padLeft(3, '0')}',
                          style: gfDisplay(10, c: GC.deepPurple),
                        ),
                      ),
                    ),
                    // indicador de long press (hint sutil)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('···', style: gfBody(10, c: Colors.white54)),
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
                      style: gfDisplay(13, c: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(date, style: gfBody(10, c: GC.textMuted)),
                        const Spacer(),
                        Text(
                          hasLocation ? '📍' : '❓',
                          style: TextStyle(fontSize: 11, color: hasLocation ? GC.pink : Colors.white24),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardOptionsSheet(cat: cat, onReload: onReload),
    );
  }
}

// ── Bottom sheet de opções do card ────────────────────────────────────────
class _CardOptionsSheet extends StatelessWidget {
  final CatEntry cat;
  final VoidCallback onReload;
  const _CardOptionsSheet({required this.cat, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final catLabel = cat.name ?? 'Gato #${cat.entryNumber.toString().padLeft(3, '0')}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GC.bgElevated, GC.bgCard],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: GC.purple.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Cabeçalho do gato
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GC.purple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GC.gold.withValues(alpha: 0.3)),
                ),
                child: const Text('🐱', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(catLabel, style: gfDisplay(17, c: Colors.white)),
                  Text(
                    '#${cat.entryNumber.toString().padLeft(3, '0')}',
                    style: gfBody(12, c: GC.gold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Compartilhar
          _OptionRow(
            icon: '📤',
            label: 'Compartilhar esse gatinho',
            color: GC.gold,
            onTap: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(cat.imagePath)],
                text: '🐾 Encontrei esse gatinho!\n$catLabel na minha Gatodex ✨\n\nTransforme, Colecione, Ame!',
              );
            },
          ),
          const SizedBox(height: 10),
          // Excluir
          _OptionRow(
            icon: '🗑️',
            label: 'Excluir da Gatodex',
            color: Colors.redAccent,
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: GC.bgCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text('Excluir $catLabel? 🗑️',
                      style: gfDisplay(16, c: Colors.white)),
                  content: Text(
                    'Essa ação não pode ser desfeita.',
                    style: gfBody(14, c: GC.textMuted),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancelar', style: gfBody(14, c: GC.textMuted)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: Text('Excluir', style: gfDisplay(14, c: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await DatabaseService().delete(cat.id!, cat.imagePath);
                onReload();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionRow({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(label, style: gfDisplay(15, c: color)),
          ],
        ),
      ),
    );
  }
}
