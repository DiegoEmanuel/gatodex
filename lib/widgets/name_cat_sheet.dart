import 'package:flutter/material.dart';
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
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gato #${widget.entryNumber.toString().padLeft(3, '0')} capturado! 🎉',
            style: const TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Você quer dar um nome a ele?',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Toggle novo / existente
          if (_existingNames.isNotEmpty) ...[
            Row(
              children: [
                _TabButton(
                  label: 'Novo nome',
                  active: _isNew,
                  onTap: () => setState(() { _isNew = true; _selected = null; }),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Já conheço esse gato',
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
              cursorColor: const Color(0xFFFF8C00),
              decoration: InputDecoration(
                hintText: 'Ex: Laranjinha, Garfield, Bichano...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF8C00)),
                ),
                prefixIcon: const Icon(Icons.edit, color: Colors.white38, size: 18),
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
                      color: active ? const Color(0xFFFF8C00) : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? const Color(0xFFFF8C00) : Colors.white24,
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _skip,
                  child: const Text('Pular', style: TextStyle(color: Colors.white38)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Salvar nome', style: TextStyle(fontWeight: FontWeight.bold)),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF8C00) : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFFFF8C00) : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
