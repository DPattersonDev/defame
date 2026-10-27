import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:defame/core/demo.dart';
import 'package:defame/features/feed.dart';
import 'package:defame/screens/home_screen.dart';
import 'package:defame/theme/app_theme.dart';

void main() {
  testWidgets('mobile layouts render without overflow in light and dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await DemoStore.start();
    const previewFont = String.fromEnvironment('PREVIEW_FONT_PATH');
    await tester.runAsync(() async {
      if (previewFont.isNotEmpty) {
        final bytes = await File(previewFont).readAsBytes();
        final sans = FontLoader('PreviewSans')
          ..addFont(Future.value(bytes.buffer.asByteData()));
        await sans.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    ThemeData preview(ThemeData theme) => theme.copyWith(
      textTheme: theme.textTheme.apply(
        fontFamily: previewFont.isEmpty ? null : 'PreviewSans',
      ),
      primaryTextTheme: theme.primaryTextTheme.apply(
        fontFamily: previewFont.isEmpty ? null : 'PreviewSans',
      ),
    );
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      final render =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('${Directory.systemTemp.path}/defame-previews')
            .create(recursive: true);
        await File('${Directory.systemTemp.path}/defame-previews/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: preview(AppTheme.lightTheme),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    await capture('welcome');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: preview(AppTheme.lightTheme),
          home: const FeedShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('feed');
    await tester.tap(find.byIcon(Icons.groups_outlined).last);
    await tester.pumpAndSettle();
    await capture('groups');
    await tester.tap(find.byIcon(Icons.person_outline).last);
    await tester.pumpAndSettle();
    await capture('profile');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: preview(AppTheme.darkTheme),
          home: const FeedShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('dark');
  });
}
