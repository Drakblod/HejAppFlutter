import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Färger ──────────────────────────────────────────────────────────────────
const _surface = Color(0xFF1A1D27);
const _border = Color(0xFF2E3245);
const _accent = Color(0xFF00D4AA);
const _accent2 = Color(0xFF005F4E);
const _textColor = Color(0xFFE8EAF0);
const _muted = Color(0xFF6B7280);
const _digitBg = Color(0xFF1E2235);

class OcrView extends StatefulWidget {
  final String groupId;

  const OcrView({super.key, required this.groupId});

  @override
  State<OcrView> createState() => _OcrViewState();
}

class _OcrViewState extends State<OcrView> {
  final _controller = TextEditingController();
  int _groupSize = 2;
  List<String> _groups = [];
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_process);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _process() {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += _groupSize) {
      final end = (i + _groupSize).clamp(0, digits.length);
      groups.add(digits.substring(i, end));
    }
    setState(() => _groups = groups);
  }

  String get _formatted => _groups.join(' ');

  Future<void> _copy() async {
    if (_formatted.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _formatted));
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Inmatning ──
          _label('Klistra in OCR-kod'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: _textColor,
              ),
              decoration: const InputDecoration(
                hintText: 't.ex. 2548755484',
                hintStyle: TextStyle(color: Color(0xFF3A3F55), fontFamily: 'monospace'),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Gruppstorlek ──
          Row(
            children: [
              const Text('Gruppstorlek:', style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(width: 8),
              for (final size in [2, 3, 4]) ...[
                _GroupButton(
                  label: '$size',
                  active: _groupSize == size,
                  onTap: () {
                    setState(() => _groupSize = size);
                    _process();
                  },
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── Resultat ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('Resultat'),
              GestureDetector(
                onTap: _copy,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _copied ? _accent : _border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _copied ? 'Kopierat ✓' : 'Kopiera',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _copied ? _accent : _muted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _groups.isEmpty
                ? const Text(
                    '— visas här —',
                    style: TextStyle(color: Color(0xFF3A3F55), fontFamily: 'monospace'),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < _groups.length; i++) ...[
                        _PairChip(
                          text: _groups[i],
                          isOdd: i < _groups.length - 1 || _groups[i].length == _groupSize,
                        ),
                        if (i < _groups.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text('·', style: TextStyle(color: _border, fontSize: 14)),
                          ),
                      ],
                    ],
                  ),
          ),

          // ── Råtext ──
          if (_formatted.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _formatted,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: _muted,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _muted,
          letterSpacing: 1.2,
        ),
      );
}

// ─── Hjälpwidgets ─────────────────────────────────────────────────────────────
class _GroupButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _GroupButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? _accent2 : _surface,
          border: Border.all(color: active ? _accent : _border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: active ? _accent : _muted,
          ),
        ),
      ),
    );
  }
}

class _PairChip extends StatelessWidget {
  final String text;
  final bool isOdd;

  const _PairChip({required this.text, required this.isOdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _digitBg,
        border: Border.all(color: isOdd ? _border : _accent2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: isOdd ? _textColor : _accent,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
