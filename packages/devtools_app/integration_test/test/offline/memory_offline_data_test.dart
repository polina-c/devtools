// Copyright 2024 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_test/helpers.dart';
import 'package:devtools_test/integration_test.dart';
import 'package:devtools_test/test_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// To run:
// dart run integration_test/run_tests.dart --target=integration_test/test/offline/memory_offline_data_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Memory screen can load offline data',
    (tester) async {
      await pumpDevTools(tester);
      await loadSampleData(tester, memoryFileName);
      await tester.pumpAndSettle(longPumpDuration);

      await tester.tap(find.text('_MyClass'));
      await tester.pumpAndSettle(shortPumpDuration);
      expect(find.text('Traced allocations for: _MyClass'), findsOneWidget);

      await tester.tap(find.text('Diff Snapshots'));
      await tester.pumpAndSettle(shortPumpDuration);
      await tester.tap(find.textContaining('main'));
      await tester.pumpAndSettle(shortPumpDuration);
      expect(find.text('_MyHomePageState'), findsOneWidget);

      await tester.tap(find.text('Profile Memory'));
      await tester.pumpAndSettle(shortPumpDuration);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('MyApp'), findsOneWidget);
    },
  );
}
