import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/rating_repository.dart';
import '../models/rating_models.dart';

Future<void> showRatingItemEditor(
  BuildContext context,
  String groupId,
  RatingArchive archive, {
  RatingItem? item,
  bool reviewOnly = false,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => RatingItemDialog(
    groupId: groupId,
    archive: archive,
    item: item,
    reviewOnly: reviewOnly,
  ),
);

class RatingItemDialog extends ConsumerStatefulWidget {
  final String groupId;
  final RatingArchive archive;
  final RatingItem? item;
  final bool reviewOnly;
  const RatingItemDialog({
    super.key,
    required this.groupId,
    required this.archive,
    this.item,
    this.reviewOnly = false,
  });
  @override
  ConsumerState<RatingItemDialog> createState() => _RatingItemDialogState();
}

class _RatingItemDialogState extends ConsumerState<RatingItemDialog> {
  final _form = GlobalKey<FormState>();
  late final String _id;
  late String _title, _comment;
  late Map<String, dynamic> _metadata, _criteria;
  num? _primary;
  bool _busy = false, _removeImage = false;
  String? _error, _imageData;
  Uint8List? _imagePreview;
  RatingConfig get config => widget.archive.config!;
  bool get _review => widget.reviewOnly || widget.item == null;
  @override
  void initState() {
    super.initState();
    _id =
        widget.item?.id ??
        'item_${DateTime.now().microsecondsSinceEpoch}_${widget.archive.userId.hashCode.abs()}';
    _title = widget.item?.title ?? '';
    _metadata = {...?widget.item?.metadata};
    final review = widget.item?.reviews[widget.archive.userId];
    _primary = review?.primaryRating;
    _criteria = {...?review?.criteria};
    _comment = review?.comment ?? '';
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 2 * 1024 * 1024) throw Exception('size');
      final type = bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80
          ? 'png'
          : bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216
          ? 'jpeg'
          : bytes.length > 12 &&
                String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
                String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'
          ? 'webp'
          : null;
      if (type == null) throw Exception('format');
      setState(() {
        _imagePreview = bytes;
        _imageData = 'data:image/$type;base64,${base64Encode(bytes)}';
        _removeImage = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Välj en JPG-, PNG- eller WebP-bild under 2 MB.',
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(ratingRepositoryProvider).call(
        widget.groupId,
        widget.reviewOnly ? 'review' : 'saveItem',
        {
          'id': _id,
          'configRevision': config.revision,
          'version': widget.item?.version ?? 0,
          'reviewVersion':
              widget.item?.reviews[widget.archive.userId]?.updatedAt ?? 0,
          'item': {'title': _title, 'metadataValues': _metadata},
          'review': {
            'primaryRating': _primary,
            'criterionRatings': _criteria,
            'comment': _comment,
          },
          if (_imageData != null) 'imageData': _imageData,
          'removeImage': _removeImage,
        },
      );
      ref.invalidate(ratingArchiveProvider(widget.groupId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ratingError(e);
        });
      }
    }
  }

  Widget _score(
    String label,
    num min,
    num max,
    num? value,
    ValueChanged<num?> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: value?.toString() ?? '',
      enabled: !_busy,
      decoration: InputDecoration(
        labelText: label,
        helperText: '$min–$max · lämna tomt för Ej betygsatt',
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      onChanged: (v) => change(num.tryParse(v.replaceAll(',', '.'))),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final number = num.tryParse(v.replaceAll(',', '.'));
        return number == null ||
                !number.isFinite ||
                number < min ||
                number > max
            ? 'Ange ett betyg mellan $min och $max'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        widget.reviewOnly
            ? 'Din recension'
            : widget.item == null
            ? 'Lägg till: ${config.itemTypeName}'
            : 'Redigera objekt',
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.reviewOnly) ...[
                  TextFormField(
                    initialValue: _title,
                    enabled: !_busy,
                    maxLength: 160,
                    decoration: const InputDecoration(labelText: 'Namn'),
                    onChanged: (v) => _title = v,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Ange ett namn' : null,
                  ),
                  const SizedBox(height: 12),
                  if (_imagePreview != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        _imagePreview!,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (widget.item?.imageUrl != null && !_removeImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        widget.item!.imageUrl!,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Välj bild'),
                      ),
                      if (_imagePreview != null ||
                          (widget.item?.imageUrl != null && !_removeImage))
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _imageData = null;
                                  _imagePreview = null;
                                  _removeImage = true;
                                }),
                          child: const Text('Ta bort bild'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final field in config.fields) _metadataField(field),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      widget.item!.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                if (_review) ...[
                  const Divider(height: 30),
                  Text(
                    'Dina betyg',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  _score(
                    config.primaryLabel,
                    config.min,
                    config.max,
                    _primary,
                    (v) => _primary = v,
                  ),
                  for (final criterion in config.criteria)
                    _score(
                      criterion['label'] as String,
                      criterion['min'] as num,
                      criterion['max'] as num,
                      _criteria[criterion['id']] as num?,
                      (v) => _criteria[criterion['id'] as String] = v,
                    ),
                  TextFormField(
                    initialValue: _comment,
                    enabled: !_busy,
                    maxLength: 4000,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Kommentar / recension',
                    ),
                    onChanged: (v) => _comment = v,
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
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
          child: Text(_busy ? 'Sparar…' : 'Spara'),
        ),
      ],
    ),
  );
  Widget _metadataField(Map<String, dynamic> f) {
    final id = f['id'] as String, type = f['type'] as String;
    final required = f['required'] == true;
    final label = '${f['label']}${required ? ' *' : ''}';
    Widget field;
    if (type == 'boolean' || type == 'dropdown') {
      final options = type == 'boolean'
          ? ['Ja', 'Nej']
          : (f['options'] as List).cast<String>();
      final initial = _metadata[id] == null
          ? ''
          : type == 'boolean'
          ? (_metadata[id] == true ? 'Ja' : 'Nej')
          : _metadata[id] as String;
      field = DropdownButtonFormField<String>(
        initialValue: initial,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: '', child: Text('Ej angivet')),
          ...options.map((v) => DropdownMenuItem(value: v, child: Text(v))),
        ],
        onChanged: _busy
            ? null
            : (v) => _metadata[id] = v == null || v.isEmpty
                  ? null
                  : type == 'boolean'
                  ? v == 'Ja'
                  : v,
        validator: (v) =>
            required && (v == null || v.isEmpty) ? 'Välj ett värde' : null,
      );
    } else {
      final numeric = type == 'number' || type == 'currency';
      field = TextFormField(
        initialValue: '${_metadata[id] ?? ''}',
        enabled: !_busy,
        decoration: InputDecoration(
          labelText: label,
          suffixText: type == 'currency' ? f['currency'] as String? : null,
          hintText: type == 'date' ? 'ÅÅÅÅ-MM-DD' : null,
        ),
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        onChanged: (v) => _metadata[id] = numeric
            ? num.tryParse(v.replaceAll(',', '.'))
            : v.trim(),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return required ? 'Fyll i $label' : null;
          }
          if (numeric) {
            final n = num.tryParse(v.replaceAll(',', '.'));
            if (n == null || !n.isFinite || n.abs() > 1e9) {
              return 'Ange ett giltigt tal';
            }
          }
          if (type == 'date') {
            final d = DateTime.tryParse(v);
            if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ||
                d == null ||
                d.toIso8601String().substring(0, 10) != v) {
              return 'Ange datum som ÅÅÅÅ-MM-DD';
            }
          }
          return null;
        },
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: field);
  }
}
