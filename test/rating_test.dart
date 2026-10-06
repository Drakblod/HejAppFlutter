import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hejapp_flutter/features/rating/data/rating_presets.dart';
import 'package:hejapp_flutter/features/rating/data/rating_repository.dart';
import 'package:hejapp_flutter/features/rating/models/rating_models.dart';
import 'package:hejapp_flutter/features/rating/presentation/rating_view.dart';
import 'package:hejapp_flutter/features/rating/presentation/rating_config_dialog.dart';
import 'package:hejapp_flutter/features/rating/presentation/rating_item_dialog.dart';

class FakeRatingRepository extends RatingRepository {
  final List<Map<String, dynamic>> calls = [];
  @override
  Future<Map<String, dynamic>> call(
    String groupId,
    String action, [
    Map<String, dynamic> data = const {},
  ]) async {
    calls.add({'groupId': groupId, 'action': action, ...data});
    return {'ok': true};
  }
}

RatingItem item(String id, String title, List<num?> scores, {num? criterion}) =>
    RatingItem({
      'id': id,
      'title': title,
      'creatorId': 'owner',
      'version': 1,
      'createdAt': 1,
      'updatedAt': 2,
      'reviews': {
        for (var i = 0; i < scores.length; i++)
          'u$i': {
            'primaryRating': scores[i],
            'criterionRatings': {
              if (criterion != null) 'tenderness': criterion,
            },
            'userId': 'u$i',
            'updatedAt': 2,
          },
      },
    });
RatingArchive archive({bool canConfigure = true}) => RatingArchive(
  config: RatingConfig({...sardineRatingConfig(), 'revision': 1}),
  items: [
    item('one', 'Ramón Peña Xeito', [9.6]),
    item('two', 'Ramón Peña Sardinillas Picantes', [9.2]),
    item('three', 'Nuri Spicy i olivolja', [8.5]),
    item('four', 'Ortiz', [null]),
  ],
  canConfigure: canConfigure,
  userId: 'owner',
);

Future<void> pump(
  WidgetTester tester,
  Widget child, {
  RatingArchive? data,
  RatingRepository? repository,
  Size size = const Size(1200, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          ratingRepositoryProvider.overrideWithValue(repository),
        ratingArchiveProvider(
          'g',
        ).overrideWith((ref) async => data ?? archive()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF225C32)),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'create form requires a name and submits absent ratings as null',
    (tester) async {
      final repository = FakeRatingRepository();
      await pump(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showRatingItemEditor(context, 'g', archive()),
            child: const Text('Open'),
          ),
        ),
        repository: repository,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spara'));
      await tester.pumpAndSettle();
      expect(repository.calls, isEmpty);
      expect(find.text('Ange ett namn'), findsOneWidget);
      final nameField = find.widgetWithText(TextFormField, 'Namn');
      await tester.enterText(nameField, 'Nytt objekt');
      await tester.tap(find.text('Spara'));
      await tester.pumpAndSettle();
      expect(repository.calls.single['action'], 'saveItem');
      expect(repository.calls.single['item']['title'], 'Nytt objekt');
      expect(repository.calls.single['review']['primaryRating'], isNull);
      expect(repository.calls.single['review']['criterionRatings'], isEmpty);
      expect(find.byType(RatingItemDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'means exclude missing values but include zero; ranking never promotes unrated items',
    () {
      final zero = item('z', 'Zero', [0, null]);
      expect(zero.score, 0);
      expect(item('a', 'Mixed', [10, null, 8]).score, 9);
      final data = RatingArchive(
        config: archive().config,
        items: [
          item('n', 'Unknown', [null]),
          zero,
          item('neg', 'Negative', [-1]),
        ],
        canConfigure: false,
        userId: 'u',
      );
      expect(data.ranked.map((i) => i.id), ['z', 'neg', 'n']);
      expect(data.topThree.length, 2);
      expect(data.highlight('tenderness'), isNull);
    },
  );
  test(
    'generic highlights, false metadata and RTDB missing arrays survive parsing',
    () {
      final data = RatingArchive.fromJson({
        'userId': 'u',
        'canConfigure': true,
        'module': {
          'config': {
            'title': 'Film',
            'itemTypeName': 'Film',
            'primaryLabel': 'Betyg',
            'min': 1,
            'max': 5,
          },
          'items': {},
        },
      });
      expect(data.config!.criteria, isEmpty);
      expect(data.config!.fields, isEmpty);
      expect(data.items, isEmpty);
      expect(metadataDisplay({'type': 'boolean'}, false), 'Nej');
      expect(ratingScore(null), 'Ej betygsatt');
      final rated = RatingArchive(
        config: archive().config,
        items: [
          item('a', 'A', [1], criterion: 9),
          item('b', 'B', [10], criterion: 2),
        ],
        canConfigure: false,
        userId: 'u',
      );
      expect(rated.highlight('tenderness')!.id, 'a');
    },
  );
  for (final width in [390.0, 1200.0]) {
    testWidgets(
      'ranking fits ${width.toInt()}px and renders missing scores honestly',
      (tester) async {
        await pump(
          tester,
          const RatingView(groupId: 'g'),
          size: Size(width, 1000),
        );
        expect(find.text('Sardinarkivet'), findsOneWidget);
        expect(find.text('Gruppens favoriter'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
        await tester.pumpAndSettle();
        expect(find.text('Helhetsbetyg: Ej betygsatt'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('members cannot configure an unconfigured module', (
    tester,
  ) async {
    await pump(
      tester,
      const RatingView(groupId: 'g'),
      data: RatingArchive(
        config: null,
        items: [],
        canConfigure: false,
        userId: 'member',
      ),
    );
    expect(find.text('Konfigurera modulen'), findsNothing);
  });
  testWidgets(
    'demo preset populates a generic configuration editor on mobile',
    (tester) async {
      await pump(
        tester,
        RatingConfigDialog(
          groupId: 'g',
          archive: RatingArchive(
            config: null,
            items: [],
            canConfigure: true,
            userId: 'owner',
          ),
        ),
        size: const Size(390, 900),
      );
      await tester.tap(find.text('Demo: Sardinarkivet'));
      await tester.pumpAndSettle();
      expect(find.text('Sardinarkivet'), findsOneWidget);
      expect(find.text('Importera 14 demoobjekt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'item editor renders configured fields on mobile and leaves criteria empty',
    (tester) async {
      await pump(
        tester,
        RatingItemDialog(groupId: 'g', archive: archive()),
        size: const Size(390, 900),
      );
      expect(find.text('Producent'), findsOneWidget);
      expect(find.text('Land'), findsOneWidget);
      expect(find.text('Skulle köpa igen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1500),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mörhet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('summary uses configured highlights without inventing ratings', (
    tester,
  ) async {
    await pump(
      tester,
      const SingleChildScrollView(child: RatingSummary(groupId: 'g')),
      size: const Size(390, 900),
    );
    expect(find.text('Mörast: Ej betygsatt'), findsOneWidget);
    expect(find.text('Bästa prisvärdhet: Ej betygsatt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
