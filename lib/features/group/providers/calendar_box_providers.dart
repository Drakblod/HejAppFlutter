import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarEvent {
  final String id, title, date, time, location, description, sourceUrl;
  CalendarEvent(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      date = json['date'] as String,
      time = json['time'] as String? ?? '',
      location = json['location'] as String? ?? '',
      description = json['description'] as String? ?? '',
      sourceUrl = json['sourceUrl'] as String? ?? '';
}

class CalendarBoxRepository {
  Future<Map<String, dynamic>> call(
    String groupId,
    String action, [
    Map<String, dynamic> fields = const {},
  ]) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable(
          'calendarBox',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 100)),
        )
        .call({'groupId': groupId, 'action': action, ...fields});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<CalendarEvent>> list(String groupId) async {
    final result = await call(groupId, 'list');
    final events = (result['events'] as List)
        .map((e) => CalendarEvent(Map<String, dynamic>.from(e as Map)))
        .toList();
    events.sort(
      (a, b) => '${a.date} ${a.time}'.compareTo('${b.date} ${b.time}'),
    );
    return events;
  }
}

final calendarBoxRepositoryProvider = Provider(
  (ref) => CalendarBoxRepository(),
);
final calendarBoxEventsProvider = FutureProvider.autoDispose
    .family<List<CalendarEvent>, String>(
      (ref, groupId) => ref.watch(calendarBoxRepositoryProvider).list(groupId),
    );

bool validCalendarDate(String input) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) return false;
  final date = DateTime.tryParse(input);
  return date != null &&
      date.year >= 2000 &&
      date.year <= 2100 &&
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}' ==
          input;
}
