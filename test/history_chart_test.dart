import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonometer_mvp/data/app_database.dart';
import 'package:tonometer_mvp/ui/history_chart.dart';

import 'test_app_harness.dart';

void main() {
  testWidgets('history chart renders three series and zoom controls', (
    tester,
  ) async {
    final now = DateTime.now();
    final measurements = [
      Measurement(
        id: 2,
        systolic: 143,
        diastolic: 90,
        pulse: 90,
        armSide: 'L',
        measuredAt: now,
        createdAt: now,
      ),
      Measurement(
        id: 1,
        systolic: 138,
        diastolic: 86,
        pulse: 75,
        armSide: 'R',
        measuredAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
      ),
      Measurement(
        id: 3,
        systolic: 250,
        diastolic: 150,
        pulse: 130,
        armSide: 'L',
        measuredAt: now.subtract(const Duration(days: 8)),
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('ru'),
        child: MeasurementHistoryChart(measurements: measurements),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SYS'), findsOneWidget);
    expect(find.text('DIA'), findsOneWidget);
    expect(find.text('Pulse'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Среднее за 7 дней: SYS 141, DIA 88, Pulse 83'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('history chart falls back to all data for averages', (
    tester,
  ) async {
    final now = DateTime.now();
    final measurements = [
      Measurement(
        id: 1,
        systolic: 150,
        diastolic: 95,
        pulse: 80,
        armSide: 'L',
        measuredAt: now.subtract(const Duration(days: 8)),
        createdAt: now,
      ),
      Measurement(
        id: 2,
        systolic: 140,
        diastolic: 85,
        pulse: 70,
        armSide: 'R',
        measuredAt: now.subtract(const Duration(days: 10)),
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('ru'),
        child: MeasurementHistoryChart(measurements: measurements),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp(r'Среднее по имеющимся данным: SYS 145, DIA 90, Pulse 75'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
