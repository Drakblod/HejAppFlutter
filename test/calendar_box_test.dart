import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hejapp_flutter/features/group/providers/calendar_box_providers.dart';
import 'package:hejapp_flutter/features/group/presentation/views/calendar_box_view.dart';

class FakeCalendar extends CalendarBoxRepository {
  final List<String> actions = [];
  @override
  Future<Map<String, dynamic>> call(
    String groupId,
    String action, [
    Map<String, dynamic> fields = const {},
  ]) async {
    actions.add(action);
    if (action == 'extract')
      return {
        'draft': {
          'title': 'Testkonsert',
          'date': null,
          'time': null,
          'warnings': ['År saknas.'],
        },
      };
    return {'id': 'saved'};
  }
}

void main() {
  test(
    'rejects overflow dates instead of silently moving them to next month',
    () {
      expect(validCalendarDate('2026-02-29'), false);
      expect(validCalendarDate('2028-02-29'), true);
      expect(validCalendarDate('2026-13-01'), false);
      expect(validCalendarDate('2026-10-24'), true);
    },
  );

  testWidgets('AI draft is not saved automatically; missing date blocks save', (
    tester,
  ) async {
    final repository = FakeCalendar();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarBoxRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CalendarEventEditor(groupId: 'g1')),
        ),
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).first,
      'Konsert 24 oktober',
    );
    await tester.tap(find.text('Tolka och skapa förslag'));
    await tester.pumpAndSettle();
    expect(repository.actions, ['extract']);
    expect(find.text('År saknas.'), findsOneWidget);
    await tester.ensureVisible(find.text('Godkänn och spara'));
    await tester.tap(find.text('Godkänn och spara'));
    await tester.pumpAndSettle();
    expect(repository.actions, ['extract']);
    expect(
      find.text('Ange ett giltigt datum, t.ex. 2026-10-24.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar empty state fits narrow mobile width', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarBoxEventsProvider('g1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CalendarBoxView(groupId: 'g1')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lägg i kalenderlådan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
