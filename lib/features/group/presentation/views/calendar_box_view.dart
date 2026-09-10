import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/calendar_box_providers.dart';

const _ink = Color(0xFF183E2B);

class CalendarBoxView extends ConsumerStatefulWidget {
  final String groupId;
  const CalendarBoxView({super.key, required this.groupId});
  @override
  ConsumerState<CalendarBoxView> createState() => _CalendarBoxViewState();
}

class _CalendarBoxViewState extends ConsumerState<CalendarBoxView> {
  bool past = false;
  @override
  Widget build(BuildContext context) {
    final events = ref.watch(calendarBoxEventsProvider(widget.groupId));
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(calendarBoxEventsProvider(widget.groupId));
            await ref.read(calendarBoxEventsProvider(widget.groupId).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 125),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KALENDERLÅDAN · TEST',
                      style: TextStyle(
                        color: Color(0xFFBDE7C7),
                        letterSpacing: 1.6,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hittat något ni vill göra?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Samla konserter, matcher och andra aktiviteter. Lägg in själv eller låt en text eller skärmdump bli ett eventförslag.',
                      style: TextStyle(color: Color(0xFFDCEAE0), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD8F3DC),
                        foregroundColor: _ink,
                      ),
                      onPressed: () => showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            CalendarEventEditor(groupId: widget.groupId),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Lägg i kalenderlådan'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Kommande'),
                    selected: !past,
                    onSelected: (_) => setState(() => past = false),
                  ),
                  ChoiceChip(
                    label: const Text('Tidigare'),
                    selected: past,
                    onSelected: (_) => setState(() => past = true),
                  ),
                  IconButton(
                    tooltip: 'Uppdatera kalendern',
                    onPressed: () => ref.invalidate(
                      calendarBoxEventsProvider(widget.groupId),
                    ),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              events.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Kalenderlådan kunde inte hämtas.'),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            calendarBoxEventsProvider(widget.groupId),
                          ),
                          child: const Text('Försök igen'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (all) {
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  final filtered = all
                      .where(
                        (e) => past
                            ? e.date.compareTo(today) < 0
                            : e.date.compareTo(today) >= 0,
                      )
                      .toList();
                  if (past) {
                    filtered.sort(
                      (a, b) => '${b.date} ${b.time}'.compareTo(
                        '${a.date} ${a.time}',
                      ),
                    );
                  }
                  if (filtered.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_available_outlined,
                              size: 44,
                              color: _ink,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              past
                                  ? 'Inga tidigare event.'
                                  : 'Här finns plats för nästa upplevelse.',
                              textAlign: TextAlign.center,
                            ),
                            if (!past)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Börja med en skärmdump eller fyll i ett event själv.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  String? previousDate;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final e in filtered) ...[
                        if (e.date != previousDate)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                            child: Text(
                              previousDate = e.date,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${e.time.isEmpty ? 'Tid ej angiven' : '${e.time} · lokal tid på platsen'}${e.location.isEmpty ? '' : '  •  ${e.location}'}',
                                ),
                                if (e.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(e.description),
                                  ),
                                if (e.sourceUrl.isNotEmpty)
                                  TextButton.icon(
                                    onPressed: () async {
                                      final url = Uri.tryParse(e.sourceUrl);
                                      try {
                                        if (url == null ||
                                            ![
                                              'https',
                                              'http',
                                            ].contains(url.scheme) ||
                                            !await launchUrl(
                                              url,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            )) {
                                          throw StateError('URL');
                                        }
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Länken kunde inte öppnas.',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 16,
                                    ),
                                    label: const Text('Öppna källa'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (all.length >= 500)
                        const Text(
                          'Testversionen visar de 500 senast tillagda eventen.',
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarEventEditor extends ConsumerStatefulWidget {
  final String groupId;
  const CalendarEventEditor({super.key, required this.groupId});
  @override
  ConsumerState<CalendarEventEditor> createState() =>
      _CalendarEventEditorState();
}

class _CalendarEventEditorState extends ConsumerState<CalendarEventEditor> {
  final form = GlobalKey<FormState>();
  final input = TextEditingController();
  final title = TextEditingController();
  final date = TextEditingController();
  final time = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();
  final source = TextEditingController();
  late final String draftId =
      '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}';
  bool review = false, busy = false, confirmed = false;
  String? error, imageData, imageName;
  Uint8List? imageBytes;
  List<String> warnings = [];

  @override
  void dispose() {
    for (final controller in [
      input,
      title,
      date,
      time,
      location,
      description,
      source,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(
          () => error = e.message ?? 'Det gick inte att slutföra. Försök igen.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Det gick inte att slutföra. Dina uppgifter finns kvar. Försök igen.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pickImage() => perform(() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    if (await image.length() > 4 * 1024 * 1024) {
      if (mounted) setState(() => error = 'Välj en bild under 4 MB.');
      return;
    }
    final bytes = await image.readAsBytes();
    String? mime;
    if (bytes.length >= 12) {
      if (bytes[0] == 0xff && bytes[1] == 0xd8) mime = 'jpeg';
      if (bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71) {
        mime = 'png';
      }
      if (ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
          ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
        mime = 'webp';
      }
    }
    if (!mounted) return;
    if (mime == null) {
      setState(() => error = 'Välj en JPG-, PNG- eller WebP-bild.');
      return;
    }
    setState(() {
      imageBytes = bytes;
      imageName = image.name;
      imageData = 'data:image/$mime;base64,${base64Encode(bytes)}';
    });
  });

  Future<void> extract() => perform(() async {
    if (input.text.trim().isEmpty && imageData == null) {
      setState(() => error = 'Klistra in eventtext eller välj en skärmdump.');
      return;
    }
    final result = await ref.read(calendarBoxRepositoryProvider).call(
      widget.groupId,
      'extract',
      {'text': input.text.trim(), 'image': imageData ?? ''},
    );
    if (!mounted) return;
    final draft = Map<String, dynamic>.from(result['draft'] as Map);
    title.text = draft['title'] as String? ?? '';
    date.text = draft['date'] as String? ?? '';
    time.text = draft['time'] as String? ?? '';
    location.text = draft['location'] as String? ?? '';
    description.text = draft['description'] as String? ?? '';
    setState(() {
      warnings = List<String>.from(draft['warnings'] as List? ?? []);
      review = true;
      confirmed = false;
    });
  });

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (!confirmed) {
      setState(() => error = 'Bekräfta att du har granskat uppgifterna.');
      return;
    }
    await perform(() async {
      await ref.read(calendarBoxRepositoryProvider).call(
        widget.groupId,
        'save',
        {
          'id': draftId,
          'confirmed': true,
          'event': {
            'title': title.text.trim(),
            'date': date.text.trim(),
            'time': time.text.trim(),
            'location': location.text.trim(),
            'description': description.text.trim(),
            'sourceUrl': source.text.trim(),
          },
        },
      );
      if (!mounted) return;
      ref.invalidate(calendarBoxEventsProvider(widget.groupId));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eventet ligger nu i kalenderlådan.')),
      );
    });
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int max = 160,
    int lines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      maxLength: max,
      maxLines: lines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (confirmed) setState(() => confirmed = false);
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFFF6F8F5),
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review ? 'Granska ditt event' : 'Lägg i kalenderlådan',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Avbryt',
                    onPressed: busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!review) ...[
                const Text(
                  'Klistra in eventets text eller välj en skärmdump. En länk ensam kan inte tolkas i den här testversionen.',
                ),
                const SizedBox(height: 16),
                field(input, 'Text från eventet', max: 12000, lines: 5),
                if (imageBytes != null) ...[
                  Image.memory(imageBytes!, height: 130, fit: BoxFit.contain),
                  Text(imageName ?? '', overflow: TextOverflow.ellipsis),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            imageBytes = null;
                            imageData = null;
                            imageName = null;
                          }),
                    child: const Text('Ta bort bilden'),
                  ),
                ],
                OutlinedButton.icon(
                  onPressed: busy ? null : pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Välj skärmdump'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vid tolkning skickas vald text och bild till OpenAI. Skärmdumpen sparas inte i kalendern.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy ? null : extract,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Tolka och skapa förslag'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          review = true;
                          error = null;
                        }),
                  child: const Text('Fyll i manuellt'),
                ),
              ] else ...[
                const Text(
                  'Kontrollera särskilt datum och år. Tom tid betyder ”tid ej angiven”. Tiden avser lokal tid på eventets plats.',
                ),
                if (warnings.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0CC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(warnings.join('\n')),
                  ),
                const SizedBox(height: 16),
                field(
                  title,
                  'Titel *',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Skriv en titel.' : null,
                ),
                field(
                  date,
                  'Datum (ÅÅÅÅ-MM-DD) *',
                  max: 10,
                  validator: (v) => validCalendarDate(v?.trim() ?? '')
                      ? null
                      : 'Ange ett giltigt datum, t.ex. 2026-10-24.',
                ),
                field(
                  time,
                  'Tid (HH:mm)',
                  max: 5,
                  validator: (v) =>
                      (v ?? '').isEmpty ||
                          RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(v!)
                      ? null
                      : 'Ange t.ex. 18:30 eller lämna tomt.',
                ),
                field(location, 'Plats', max: 300),
                field(description, 'Beskrivning', max: 3000, lines: 3),
                field(
                  source,
                  'Källänk (valfri)',
                  max: 2000,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final url = Uri.tryParse(v.trim());
                    return url != null &&
                            ['http', 'https'].contains(url.scheme) &&
                            url.host.isNotEmpty &&
                            url.userInfo.isEmpty
                        ? null
                        : 'Ange en giltig http- eller https-länk.';
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: confirmed,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => confirmed = v ?? false),
                  title: const Text(
                    'Jag har granskat uppgifterna och vill dela eventet med gruppen.',
                  ),
                ),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: const Text('Godkänn och spara'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          review = false;
                          error = null;
                        }),
                  child: const Text('Tillbaka till import'),
                ),
              ],
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFFB3261E)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
