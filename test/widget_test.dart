import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo/main.dart';
import 'package:demo/l10n/app_localizations.dart';

void main() {
  testWidgets('DrawingScannerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DrawingScannerApp(),
      ),
    );

    expect(find.text('图纸归档'), findsOneWidget);
    expect(find.text('图纸扫描入库系统'), findsOneWidget);
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('相册'), findsOneWidget);
    expect(find.text('搜索已归档图纸'), findsOneWidget);
  });
}
