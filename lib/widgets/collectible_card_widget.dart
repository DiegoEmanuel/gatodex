import 'dart:io';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/cat_entry.dart';

// ── Rarity styling ──────────────────────────────────────────────────────────

class _RarityStyle {
  final List<Color> gradient;
  final Color borderColor;
  final Color accentColor;

  const _RarityStyle({
    required this.gradient,
    required this.borderColor,
    required this.accentColor,
  });
}

const _rarityStyles = <String, _RarityStyle>{
  'Comum': _RarityStyle(
    gradient: [Color(0xFF546E7A), Color(0xFF1C2B35)],
    borderColor: Color(0xFFB0BEC5),
    accentColor: Color(0xFFCFD8DC),
  ),
  'Raro': _RarityStyle(
    gradient: [Color(0xFF1565C0), Color(0xFF0A1929)],
    borderColor: Color(0xFF42A5F5),
    accentColor: Color(0xFF90CAF9),
  ),
  'Épico': _RarityStyle(
    gradient: [Color(0xFF6A1B9A), Color(0xFF1A0050)],
    borderColor: Color(0xFFBA68C8),
    accentColor: Color(0xFFE1BEE7),
  ),
  'Lendário': _RarityStyle(
    gradient: [Color(0xFFBF360C), Color(0xFF1C0700)],
    borderColor: Color(0xFFFFD54F),
    accentColor: Color(0xFFFFECB3),
  ),
  'Mítico': _RarityStyle(
    gradient: [Color(0xFF880E4F), Color(0xFF0D0627)],
    borderColor: Color(0xFFFF4081),
    accentColor: Color(0xFFFF80AB),
  ),
};

const _elementEmoji = <String, String>{
  'Fogo': '🔥',
  'Gelo': '❄️',
  'Luz': '✨',
  'Sombra': '🌑',
  'Natureza': '🌿',
  'Elétrico': '⚡',
  'Místico': '🔮',
};

// ── Main widget ──────────────────────────────────────────────────────────────

class CollectibleCardWidget extends StatelessWidget {
  final CatEntry cat;

  const CollectibleCardWidget({super.key, required this.cat});

  @override
  Widget build(BuildContext context) {
    final style = _rarityStyles[cat.rarity] ?? _rarityStyles['Comum']!;
    final emoji = _elementEmoji[cat.element] ?? '✨';
    final displayName = cat.cardName ?? cat.name ?? 'Gato #${cat.entryNumber}';

    return Container(
      width: 280,
      height: 420,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: style.borderColor.withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildPhotoSection(style, emoji),
            _buildInfoSection(style, emoji, displayName),
          ],
        ),
      ),
    );
  }

  // ── Photo area (top 220px) ─────────────────────────────────────────────────

  Widget _buildPhotoSection(_RarityStyle style, String emoji) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cat photo
          Image.file(
            File(cat.imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: GC.bgElevated,
              child: const Center(
                child: Text('🐈', style: TextStyle(fontSize: 64)),
              ),
            ),
          ),

          // Top overlay — makes header badges readable
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom overlay — blends into info section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    style.gradient.last.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          // Header: entry number (left) + rarity (right)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Pill(
                  text: '#${cat.entryNumber.toString().padLeft(3, '0')}',
                  bg: GC.gold,
                  textColor: GC.deepPurple,
                ),
                _Pill(
                  text: (cat.rarity ?? 'Comum').toUpperCase(),
                  bg: style.borderColor,
                  textColor: Colors.black87,
                ),
              ],
            ),
          ),

          // Element badge — bottom-right corner of photo
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                border: Border.all(color: style.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: style.borderColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info area (bottom 200px) ───────────────────────────────────────────────

  Widget _buildInfoSection(
    _RarityStyle style,
    String emoji,
    String displayName,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              displayName,
              style: gfDisplay(18, c: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // Element
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  cat.element ?? '',
                  style: gfBody(11, c: style.accentColor),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatBox('POD', cat.power ?? 0, style),
                _StatBox('AGI', cat.agility ?? 0, style),
                _StatBox('CAR', cat.charisma ?? 0, style),
              ],
            ),
            const SizedBox(height: 9),

            // Ability
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: style.borderColor.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '✦ ',
                    style: TextStyle(
                      color: style.accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      cat.ability ?? '',
                      style: gfDisplay(12, c: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    ' ✦',
                    style: TextStyle(
                      color: style.accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Branding
            Center(
              child: Text(
                '✦ GATODEX ✦',
                style: gfBody(
                  9,
                  c: GC.gold.withValues(alpha: 0.75),
                  w: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const _Pill({required this.text, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.5), blurRadius: 6)],
      ),
      child: Text(text, style: gfDisplay(9, c: textColor)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final _RarityStyle style;

  const _StatBox(this.label, this.value, this.style);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: style.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: gfDisplay(16, c: style.accentColor),
          ),
          Text(
            label,
            style: gfBody(9, c: Colors.white60, w: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
