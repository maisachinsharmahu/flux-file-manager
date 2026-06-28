import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux/app.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FluxApp(),
      ),
    );

    // Verify main app interface elements load.
    expect(find.byType(FluxApp), findsOneWidget);
  });
}
