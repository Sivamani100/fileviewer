import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:filevault/features/file_manager/file_manager_screen.dart';

void main() {
  testWidgets('FileManager category tiles are displayed when path is empty',
      (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: FileManagerScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('All Files'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
  });

  testWidgets('FileManager can load directory and select file',
      (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final DIRECTORY = Directory.systemTemp.createTempSync('filevault_test');
    final file = File('${DIRECTORY.path}${Platform.pathSeparator}testfile.txt');
    await file.writeAsString('hello');

    print('DEBUG: set up temp dir ${DIRECTORY.path} and file');

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: FileManagerScreen(currentPath: DIRECTORY.path),
      ),
    ));

    print('DEBUG: widget pumped');

    await tester.pump();

    print('DEBUG: after pump');

    expect(find.text('testfile.txt'), findsOneWidget);

    // long press to select; selection triggers delete icon in app bar
    await tester.longPress(find.text('testfile.txt'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete), findsOneWidget);

    // verify the delete action appears when file selected
    expect(find.byIcon(Icons.delete), findsOneWidget);

    if (DIRECTORY.existsSync()) {
      DIRECTORY.deleteSync(recursive: true);
    }
  });
}


