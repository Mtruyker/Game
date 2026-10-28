import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_of_time/main.dart';

void main() {
  testWidgets('shows the three historical eras', (WidgetTester tester) async {
    await tester.pumpWidget(const MirrorGame());
    expect(find.text('Средневековье'), findsOneWidget);
    expect(find.text('Эпоха великих открытий'), findsOneWidget);
    expect(find.text('Новейшее время'), findsOneWidget);
  });
}
