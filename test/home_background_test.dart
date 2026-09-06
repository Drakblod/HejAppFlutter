import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hejapp_flutter/core/models/group.dart';
import 'package:hejapp_flutter/core/widgets/living_background.dart';
import 'package:hejapp_flutter/features/home/presentation/screens/home_screen.dart';
import 'package:hejapp_flutter/features/home/providers/group_providers.dart';

void main() {
  setUpAll(() async {
    // Use the SDK's real font metrics instead of Flutter tests' wide Ahem font.
    final config = File('.dart_tool/package_config.json');
    final packages =
        jsonDecode(await config.readAsString())['packages'] as List;
    final flutter = packages.firstWhere((entry) => entry['name'] == 'flutter');
    final flutterRoot = config.absolute.uri.resolve('${flutter['rootUri']}/');
    final font = File.fromUri(
      flutterRoot.resolve(
        '../../bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      ),
    );
    await (FontLoader('Roboto')..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        ))
        .load();
  });
  for (final width in [390.0, 1536.0]) {
    testWidgets('Home shows the background and spaces at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 864);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userGroupsProvider.overrideWith(
              (ref) => Stream.value([
                for (var i = 0; i < 6; i++)
                  Group.fromJson('space-$i', {
                    'name': 'Space ${i + 1}',
                    'icon': 'H',
                  }),
              ]),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(colorSchemeSeed: const Color(0xFF225C32)),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(LivingBackground), findsOneWidget);
      expect(find.text('Your spaces'), findsOneWidget);
      expect(find.text('Space 1'), findsOneWidget);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.transparent,
      );
      expect(tester.takeException(), isNull);
      // Optional local visual QA; no generated image is required by the test.
      if (const bool.fromEnvironment('CAPTURE_HOME')) {
        await expectLater(
          find.byType(HomeScreen),
          matchesGoldenFile('../build/home-preview-$width.png'),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'Reduced motion stops animation and controls still receive taps',
    (tester) async {
      var taps = 0;
      Widget screen(bool reduced) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: LivingBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: TextButton(
                onPressed: () => taps++,
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(screen(false));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpWidget(screen(true));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tap(find.text('Open'));
      expect(taps, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
