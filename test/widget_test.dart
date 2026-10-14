import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_monitor_mobile/app.dart';
import 'package:zoom_monitor_mobile/core/providers/core_providers.dart';

void main() {
  testWidgets('App renders SplashScreen on launch smoke test',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const ZoomMonitorApp(),
      ),
    );

    // Initial splash frame
    expect(find.text('Zoom Monitor'), findsOneWidget);
    expect(find.text('Ruang kerja rapat perusahaan'), findsOneWidget);

    // Advance fake async timer to drain splash screen Future.delayed
    await tester.pump(const Duration(milliseconds: 800));
  });
}
