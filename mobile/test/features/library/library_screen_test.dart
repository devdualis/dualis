import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/features/library/domain/library_catalog.dart';
import 'package:dualis_mobile/features/library/presentation/library_screen.dart';
import 'package:dualis_mobile/l10n/app_localizations.dart';

Future<void> pumpLibrary(WidgetTester tester, String locale) async {
  tester.view.physicalSize = const Size(800, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LibraryScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> renderedArticleIds(WidgetTester tester) {
  return tester
      .widgetList<LibraryArticleTile>(find.byType(LibraryArticleTile))
      .map((t) => t.article.id)
      .toList();
}

void main() {
  testWidgets('shows the eight wellness topics in fixed order', (tester) async {
    await pumpLibrary(tester, 'pt');
    final titles = [
      'Emoções e humor',
      'Estresse e descanso',
      'Sono',
      'Corpo e movimento',
      'Alimentação e digestão',
      'Hidratação',
      'Relações e convívio',
      'Primeiros cuidados e quando procurar ajuda',
    ];
    double? lastY;
    for (final title in titles) {
      final finder = find.text(title);
      expect(finder, findsOneWidget, reason: title);
      final y = tester.getTopLeft(finder).dy;
      if (lastY != null) expect(y, greaterThan(lastY));
      lastY = y;
    }
  });

  testWidgets('every article shows its real public source', (tester) async {
    await pumpLibrary(tester, 'pt');
    for (final article in kLibraryArticles) {
      expect(article.url, startsWith('https://'));
      expect(find.text('Fonte: ${article.source}'), findsWidgets);
    }
  });

  testWidgets('same articles in the same order for everyone', (tester) async {
    await pumpLibrary(tester, 'pt');
    final first = renderedArticleIds(tester);
    await pumpLibrary(tester, 'en');
    final second = renderedArticleIds(tester);
    expect(second, first);
    final expected = [
      for (final c in LibraryCategory.values)
        ...kLibraryArticles.where((a) => a.category == c).map((a) => a.id),
    ];
    expect(first, expected);
  });

  test('library has no input that could reorder it', () {
    // LibraryScreen takes no parameters and the catalog is unmodifiable.
    expect(() => kLibraryArticles.add(kLibraryArticles.first),
        throwsUnsupportedError);
    expect(libraryByCategory().keys.toList(), LibraryCategory.values);
  });
}
