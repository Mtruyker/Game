import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_of_time/main.dart';

/// The mirror face animates forever, so pump for a fixed time instead of pumpAndSettle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openFirstQuestion(WidgetTester tester) async {
  await tester.pumpWidget(const MirrorGame());
  await tester.tap(find.text('Средневековье'));
  await settle(tester);
  await tester.tap(find.text('Вопрос 1'));
  await tester.pump(const Duration(milliseconds: 800));
  await settle(tester);
}

void main() {
  testWidgets('shows the three historical eras', (WidgetTester tester) async {
    await tester.pumpWidget(const MirrorGame());
    expect(find.text('Средневековье'), findsOneWidget);
    expect(find.text('Эпоха великих открытий'), findsOneWidget);
    expect(find.text('Новейшее время'), findsOneWidget);
  });

  testWidgets('wrong answer cracks the mirror and hides the correct option', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openFirstQuestion(tester);

    await tester.tap(find.text('Гладиатор'));
    await settle(tester);

    expect(find.text('ХМ… ТРЕЩИНА!'), findsOneWidget);
    expect(find.text('ПОПРОБОВАТЬ ЕЩЁ РАЗ'), findsOneWidget);
    // The fact (and thus the answer) is not revealed after a mistake.
    expect(find.textContaining('Рыцари служили'), findsNothing);
  });

  testWidgets('three mistakes break the mirror', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await openFirstQuestion(tester);

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text(i == 0 ? 'Гладиатор' : 'Легионер'));
      await settle(tester);
      await tester.tap(find.text('ПОПРОБОВАТЬ ЕЩЁ РАЗ'));
      await settle(tester);
    }
    await tester.tap(find.text('Гладиатор'));
    await settle(tester);
    expect(find.text('ЗЕРКАЛО РАЗБИЛОСЬ'), findsOneWidget);

    await tester.tap(find.text('К ИТОГАМ'));
    await settle(tester);
    expect(find.text('ПОПРОБОВАТЬ СНОВА'), findsOneWidget);
    expect(find.text('0 из 3'), findsOneWidget);
  });
}
