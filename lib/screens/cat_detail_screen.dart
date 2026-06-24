import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_theme.dart';
import '../models/cat_entry.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../widgets/collectible_card_widget.dart';

class CatDetailScreen extends StatefulWidget {
  final CatEntry cat;
  final VoidCallback? onReload;

  const CatDetailScreen({super.key, required this.cat, this.onReload});

  @override
  State<CatDetailScreen> createState() => _CatDetailScreenState();
}

class _CatDetailScreenState extends State<CatDetailScreen>
    with SingleTickerProviderStateMixin {
  late CatEntry _cat;
  bool _generating = false;
  bool _sharing = false;

  final _cardKey = GlobalKey();
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    _cat = widget.cat;
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );
    if (_cat.hasCard) _revealController.value = 1.0;
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  // ── Generate card via Gemini ───────────────────────────────────────────────

  Future<void> _generateCard() async {
    setState(() => _generating = true);
    try {
      final data = await GeminiService().analyzePhoto(_cat.imagePath);
      await DatabaseService().updateCard(
        _cat.id!,
        cardName: data.cardName,
        rarity: data.rarity,
        element: data.element,
        power: data.power,
        agility: data.agility,
        charisma: data.charisma,
        ability: data.ability,
      );
      setState(() {
        _cat = _cat.copyWith(
          cardName: data.cardName,
          rarity: data.rarity,
          element: data.element,
          power: data.power,
          agility: data.agility,
          charisma: data.charisma,
          ability: data.ability,
        );
      });
      widget.onReload?.call();
      _revealController.forward(from: 0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar carta: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  // ── Export card as PNG → share + upload ───────────────────────────────────

  Future<void> _shareCard() async {
    setState(() => _sharing = true);
    try {
      // Give Flutter one frame to finish rendering the RepaintBoundary
      await Future.delayed(const Duration(milliseconds: 80));

      final boundary =
          _cardKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Write to temp file for immediate sharing
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/gatodex_card_${_cat.id}.png',
      );
      await file.writeAsBytes(pngBytes);

      // Upload to Firebase Storage in background (non-blocking)
      _uploadCard(pngBytes);

      final label =
          _cat.cardName ?? _cat.name ?? 'Gato #${_cat.entryNumber}';
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '🐾 $label — ${_cat.rarity} no Gatodex!\n✨ Transforme, Colecione, Ame!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _uploadCard(Uint8List bytes) async {
    try {
      final url = await StorageService().uploadCardImage(_cat.id!, bytes);
      await DatabaseService().updateCardImageUrl(_cat.id!, url);
      if (mounted) {
        setState(() => _cat = _cat.copyWith(cardImageUrl: url));
      }
    } catch (_) {
      // silent — share already happened, storage failure is non-critical
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final label =
        _cat.cardName ??
        _cat.name ??
        'Gato #${_cat.entryNumber.toString().padLeft(3, '0')}';

    return Scaffold(
      backgroundColor: GC.bgDeep,
      appBar: AppBar(
        backgroundColor: GC.bgDeep,
        title: Text(label, style: gfDisplay(18, c: GC.gold)),
        iconTheme: const IconThemeData(color: GC.gold),
        actions: [
          if (_cat.hasCard)
            _sharing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: GC.gold,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.ios_share_rounded, color: GC.gold),
                    tooltip: 'Compartilhar carta',
                    onPressed: _shareCard,
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
      ),
      body: _cat.hasCard ? _buildCardView() : _buildGenerateView(),
    );
  }

  // ── Card revealed ──────────────────────────────────────────────────────────

  Widget _buildCardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        children: [
          // Animated reveal
          ScaleTransition(
            scale: _revealAnimation,
            child: RepaintBoundary(
              key: _cardKey,
              child: CollectibleCardWidget(cat: _cat),
            ),
          ),
          const SizedBox(height: 28),

          // Rarity row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip('${_cat.rarity}', GC.gold),
              const SizedBox(width: 10),
              _InfoChip('${_cat.element}', GC.purpleLight),
            ],
          ),
          const SizedBox(height: 20),

          // Share button
          _GoldButton(
            icon: '📤',
            label: 'Compartilhar Carta',
            onPressed: _sharing ? null : _shareCard,
          ),
          const SizedBox(height: 12),

          // Re-generate option
          TextButton(
            onPressed: _generating ? null : _generateCard,
            child: Text(
              '🔄 Gerar nova carta',
              style: gfBody(13, c: GC.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ── Generate prompt ────────────────────────────────────────────────────────

  Widget _buildGenerateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cat photo preview
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: GC.gold.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: GC.purple.withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(_cat.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('🐈', style: TextStyle(fontSize: 64)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              _cat.name ?? 'Gato #${_cat.entryNumber}',
              style: gfDisplay(20, c: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Transforme em uma carta colecionável!',
              style: gfBody(14, c: GC.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (_generating)
              Column(
                children: [
                  const CircularProgressIndicator(color: GC.gold),
                  const SizedBox(height: 16),
                  Text(
                    '✨ A IA está analisando o gato...',
                    style: gfBody(14, c: GC.goldLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Descobrindo raridade, elemento e poderes...',
                    style: gfBody(12, c: GC.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              _GoldButton(
                icon: '✨',
                label: 'Gerar Carta Mágica',
                onPressed: _generateCard,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _GoldButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onPressed;

  const _GoldButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [GC.gold, Color(0xFFFFB300)],
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
          foregroundColor: GC.deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        icon: Text(icon, style: const TextStyle(fontSize: 20)),
        label: Text(label, style: gfDisplay(15, c: GC.deepPurple)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: gfDisplay(13, c: color)),
    );
  }
}
