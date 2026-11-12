import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geoleq_application/main.dart';
import 'package:geoleq_application/services/dummy_telemetry_service.dart';

void main() {
  tearDown(() {
    DummyTelemetryService().stop();
  });

  testWidgets('GeoLeqApp builds and displays navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GeoLeqApp(),
      ),
    );

    expect(find.text('Monitor'), findsOneWidget);
    expect(find.text('Peta OSM'), findsOneWidget);
    expect(find.text('Grafik'), findsOneWidget);
    expect(find.text('Perangkat'), findsOneWidget);

    DummyTelemetryService().stop();
  });
}
