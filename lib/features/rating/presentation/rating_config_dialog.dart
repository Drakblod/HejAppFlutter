import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/rating_presets.dart';
import '../data/rating_repository.dart';
import '../models/rating_models.dart';

Future<void> showRatingConfig(
  BuildContext context,
  String groupId,
  RatingArchive archive,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => RatingConfigDialog(groupId: groupId, archive: archive),
);

class RatingConfigDialog extends ConsumerStatefulWidget {
  final String groupId;
  final RatingArchive archive;
  const RatingConfigDialog({
    super.key,
    required this.groupId,
    required this.archive,
  });
  @override
  ConsumerState<RatingConfigDialog> createState() => _RatingConfigDialogState();
}

class _RatingConfigDialogState extends ConsumerState<RatingConfigDialog> {
  final _form = GlobalKey<FormState>();
  late Map<String, dynamic> _draft;
  bool _busy = false, _demo = false;
  bool _presetSelected = false;
  String? _error;
  int _generation = 0, _counter = 0;
  bool get _locked => widget.archive.items.isNotEmpty;
  @override
  void initState() {
    super.initState();
    _draft = ratingMap(
      jsonDecode(
        jsonEncode(widget.archive.config?.json ?? blankRatingConfig()),
      ),
    );
  }

  List<dynamic> get _criteria => _draft['criteria'] as List;
  List<dynamic> get _fields => _draft['metadataFields'] as List;
  String _newId() =>
      'field_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
  Widget _text(
    Map value,
    String key,
    String label, {
    bool required = true,
    bool enabled = true,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      key: ValueKey('${value['id'] ?? 'main'}_$key'),
      initialValue: '${value[key] ?? ''}',
      enabled: enabled && !_busy,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'Fyll i $label';
        if (numeric && num.tryParse((v ?? '').replaceAll(',', '.')) == null) {
          return 'Ange ett tal';
        }
        return null;
      },
      onChanged: (v) =>
          value[key] = numeric ? num.tryParse(v.replaceAll(',', '.')) : v,
    ),
  );
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(ratingRepositoryProvider)
          .call(widget.groupId, 'configure', {
            'revision': widget.archive.config?.revision ?? 0,
            'config': _draft,
            if (_demo) 'seed': 'sardines',
          });
      ref.invalidate(ratingArchiveProvider(widget.groupId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ratingError(e);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Forma ert eget arkiv'),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              key: ValueKey(_generation),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Namn, fält och betyg styr hela upplevelsen. Samma modul fungerar för allt ni vill upptäcka och jämföra.',
                ),
                const SizedBox(height: 20),
                if (widget.archive.config == null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _draft = blankRatingConfig();
                                _demo = false;
                                _presetSelected = false;
                                _generation++;
                              }),
                        child: const Text('Tom mall'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                _draft = sardineRatingConfig();
                                _demo = true;
                                _presetSelected = true;
                                _generation++;
                              }),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Demo: Sardinarkivet'),
                      ),
                    ],
                  ),
                  if (_presetSelected)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Importera 14 demoobjekt'),
                      subtitle: const Text(
                        'Endast angivna helhetsbetyg. Inga påhittade kriteriebetyg eller bilder.',
                      ),
                      value: _demo,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _demo = v),
                    ),
                  const SizedBox(height: 16),
                ],
                _text(_draft, 'title', 'Modulens namn'),
                _text(_draft, 'itemTypeName', 'Vad betygsätter ni? (singular)'),
                _text(_draft, 'primaryLabel', 'Primärt betyg'),
                Row(
                  children: [
                    Expanded(
                      child: _text(
                        _draft,
                        'min',
                        'Min',
                        numeric: true,
                        enabled: !_locked,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _text(
                        _draft,
                        'max',
                        'Max',
                        numeric: true,
                        enabled: !_locked,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visa sammanfattning på grupptavlan'),
                  value: _draft['showSummary'] == true,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _draft['showSummary'] = v),
                ),
                if (_locked)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Befintliga skalor och fälttyper är låsta för att bevara betydelsen av era betyg. Namn, synlighet och highlights kan ändras. Nya fält är valfria.',
                    ),
                  ),
                const Divider(height: 32),
                Text(
                  'Bedömningskriterier',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final raw in _criteria) _criterion(raw),
                if (_criteria.length < 16)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(
                            () => _criteria.add({
                              'id': _newId(),
                              'label': '',
                              'min': _draft['min'],
                              'max': _draft['max'],
                              'showInRanking': false,
                              'highlightLabel': '',
                            }),
                          ),
                    icon: const Icon(Icons.add),
                    label: const Text('Lägg till kriterium'),
                  ),
                const Divider(height: 32),
                Text(
                  'Metadatafält',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final raw in _fields) _field(raw as Map),
                if (_fields.length < 16)
                  TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(
                            () => _fields.add({
                              'id': _newId(),
                              'label': '',
                              'type': 'text',
                              'options': <String>[],
                              'required': false,
                              'currency': 'SEK',
                            }),
                          ),
                    icon: const Icon(Icons.add),
                    label: const Text('Lägg till metadatafält'),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Sparar…' : 'Spara konfiguration'),
        ),
      ],
    ),
  );
  Widget _criterion(dynamic raw) {
    final c = raw as Map;
    final existing =
        _locked &&
        widget.archive.config!.criteria.any((v) => v['id'] == c['id']);
    return Card(
      key: ValueKey(c['id']),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _text(c, 'label', 'Kriteriets namn'),
            Row(
              children: [
                Expanded(
                  child: _text(
                    c,
                    'min',
                    'Min',
                    numeric: true,
                    enabled: !existing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _text(
                    c,
                    'max',
                    'Max',
                    numeric: true,
                    enabled: !existing,
                  ),
                ),
              ],
            ),
            _text(
              c,
              'highlightLabel',
              'Highlight-rubrik (valfri)',
              required: false,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visa också i ranking'),
              value: c['showInRanking'] == true,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => c['showInRanking'] = v),
            ),
            if (!existing)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _criteria.remove(raw)),
                  child: const Text('Ta bort kriterium'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(Map f) {
    final existing =
        _locked && widget.archive.config!.fields.any((v) => v['id'] == f['id']);
    const types = {
      'text': 'Text',
      'dropdown': 'Alternativ',
      'number': 'Tal',
      'currency': 'Belopp + valuta',
      'boolean': 'Ja / nej',
      'date': 'Datum',
    };
    return Card(
      key: ValueKey(f['id']),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _text(f, 'label', 'Fältnamn'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: f['type'] as String,
              decoration: const InputDecoration(labelText: 'Fälttyp'),
              items: types.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: _busy || existing
                  ? null
                  : (v) => setState(() => f['type'] = v),
            ),
            const SizedBox(height: 12),
            if (f['type'] == 'dropdown')
              TextFormField(
                initialValue: (f['options'] as List? ?? []).join(', '),
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Alternativ, separerade med kommatecken',
                ),
                onChanged: (v) => f['options'] = v
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ange alternativ' : null,
              ),
            if (f['type'] == 'currency')
              _text(f, 'currency', 'Valuta', enabled: !existing),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obligatoriskt'),
              value: f['required'] == true,
              onChanged: _busy || _locked
                  ? null
                  : (v) => setState(() => f['required'] = v),
            ),
            if (!existing)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _fields.remove(f)),
                  child: const Text('Ta bort fält'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
