import 'package:cleantrail/data/project_store.dart';
import 'package:cleantrail/domain/quality_engine.dart';
import 'package:cleantrail/main.dart';
import 'package:cleantrail/state/workbench_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_csv_gateway.dart';

void main() {
  testWidgets('sample opens the complete repair workspace in both languages', (
    tester,
  ) async {
    final controller = WorkbenchController(
      engine: const QualityEngine(),
      store: MemoryProjectStore(),
      gateway: FakeCsvGateway(),
    );

    await tester.pumpWidget(CleanTrailApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('A calm checkpoint before analysis'), findsOneWidget);
    expect(find.text('Try built-in sample'), findsOneWidget);

    await tester.ensureVisible(find.text('Try built-in sample'));
    await tester.tap(find.text('Try built-in sample'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('project-dashboard')), findsOneWidget);
    expect(find.text('quality_sample.csv'), findsOneWidget);
    expect(find.text('Repair queue'), findsOneWidget);

    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();

    expect(find.text('修复队列'), findsOneWidget);
    expect(find.text('导出文件包'), findsWidgets);
  });

  testWidgets('privacy is reachable and scrollable in the empty workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final controller = WorkbenchController(
      engine: const QualityEngine(),
      store: MemoryProjectStore(),
      gateway: FakeCsvGateway(),
    );
    await tester.pumpWidget(CleanTrailApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.privacy_tip_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.text('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
