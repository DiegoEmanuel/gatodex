import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/database_service.dart';

class NameCatSheet extends StatefulWidget {
  final int catId;
  final int entryNumber;

  const NameCatSheet({super.key, required this.catId, required this.entryNumber});

  @override
  State<NameCatSheet> createState() => _NameCatSheetState();
}

class _NameCatSheetState extends State<NameCatSheet> {
  final _controller = TextEditingController();
  List<String> _existingNames = [];
  String? _selected;
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final names = await DatabaseService().getExistingNames();
    if (mounted) setState(() => _existingNames = names);
  }

  Future<void> _save() async {
    final name = _isNew ? _controller.text.trim() : _selected;
    if (name != null && name.isNotEmpty) {
      await DatabaseService().updateName(widget.catId, name);
    }
    if (mounted) Navigator.pop(context, name);
  }

  void _skip() => Navigator.pop(context, null);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: GC.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GC.purple.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gato #${widget.entryNumber.toString().padLeft(3, '0')} capturado!',
                    style: const TextStyle(
                      color: GC.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Você quer dar um nome a ele?',
                    style: TextStyle(color: GC.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_existingNames.isNotEmpty) ...[
            Row(
              children: [
                _TabButton(
                  label: '✏️ Novo nome',
                  active: _isNew,
                  onTap: () => setState(() { _isNew = true; _selected = null; }),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: '🐱 Já conheço',
                  active: !_isNew,
                  onTap: () => setState(() { _isNew = false; _controller.clear(); }),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          if (_isNew)
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: GC.gold,
              decoration: InputDecoration(
                hintText: 'Ex: Laranjinha, Garfield, Bichano...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                filled: true,
                fillColor: GC.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: GC.gold, width: 1.5),
                ),
                prefixIcon: const Icon(Icons.pets, color: GC.textMuted, size: 18),
              ),
              onSubmitted: (_) => _save(),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _existingNames.map((name) {
                final active = _selected == name;
                return GestureDetector(
                  onTap: () => setState(() => _selected = name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? GC.gold : GC.bgElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? GC.gold : GC.purple.withValues(alpha: 0.4),
                      ),
                      boxShadow: active
                          ? [BoxShadow(color: GC.gold.withValues(alpha: 0.3), blurRadius: 8)]
                          : null,
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: active ? const Color(0xFF1A0050) : Colors.white70,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: _skip,
                child: const Text('Pular', style: TextStyle(color: GC.textMuted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [GC.gold, Color(0xFFFFB300)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: GC.gold.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF1A0050),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Salvar nome 🐾',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? GC.purple : GC.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? GC.purpleLight : GC.purple.withValues(alpha: 0.35),
          ),
          boxShadow: active
              ? [BoxShadow(color: GC.purple.withValues(alpha: 0.4), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : GC.textMuted,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
