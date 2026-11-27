import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/shared/widgets/dualis_text_field.dart';

// Sized so the test font (Ahem, square glyphs) wraps them to 2-4 lines in a
// 390 pt wide field, which is what the maxLines assertions below check.
const _longHelper = 'Use o formato dd/mm/aaaa, por exemplo 15/05/1990 para continuar.';
const _longError = 'A senha deve ter pelo menos 8 caracteres, com letra e número.';

/// iPhone 15 logical width (390 pt) at 3x.
void _setPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    ),
  );
}

void main() {
  group('DualisTextField helper and error text wrapping', () {
    testWidgets('helper text allows up to 4 lines instead of one truncated line',
        (WidgetTester tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(
        _host(
          const DualisTextField(
            labelText: 'Data de nascimento',
            helperText: _longHelper,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text(_longHelper)).maxLines, 4);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(_longHelper));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.height, greaterThan(20 * 1.5),
          reason: 'long helper text should wrap onto more than one line');
    });

    testWidgets('error text allows up to 4 lines instead of one truncated line',
        (WidgetTester tester) async {
      _setPhoneSize(tester);
      await tester.pumpWidget(
        _host(
          const DualisTextField(
            labelText: 'Senha',
            errorText: _longError,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text(_longError)).maxLines, 4);
      final paragraph = tester.renderObject<RenderParagraph>(find.text(_longError));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.height, greaterThan(20 * 1.5),
          reason: 'long error text should wrap onto more than one line');
    });

    testWidgets('custom helperMaxLines and errorMaxLines are forwarded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const DualisTextField(
            labelText: 'Campo',
            helperText: _longHelper,
            helperMaxLines: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text(_longHelper)).maxLines, 2);

      // Error text replaces the helper while shown, so check it separately.
      await tester.pumpWidget(
        _host(
          const DualisTextField(
            labelText: 'Campo',
            errorText: _longError,
            errorMaxLines: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text(_longError)).maxLines, 3);
    });
  });

  group('DualisTextField autovalidate', () {
    testWidgets('only the field being edited validates when autovalidateMode is set',
        (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _host(
          Form(
            key: formKey,
            child: Column(
              children: [
                DualisTextField(
                  key: const Key('a'),
                  labelText: 'A',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => (v ?? '').isEmpty ? 'obrigatório' : null,
                ),
                DualisTextField(
                  key: const Key('b'),
                  labelText: 'B',
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => (v ?? '').isEmpty ? 'obrigatório' : null,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('a')), 'x');
      await tester.pumpAndSettle();

      expect(_hasError(tester, 'a'), isFalse);
      expect(_hasError(tester, 'b'), isFalse);

      await tester.enterText(find.byKey(const Key('a')), '');
      await tester.pumpAndSettle();
      expect(_hasError(tester, 'a'), isTrue);
      expect(_hasError(tester, 'b'), isFalse);
    });
  });
}

bool _hasError(WidgetTester tester, String key) {
  final state = tester.state<FormFieldState<String>>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextFormField),
    ),
  );
  return state.hasError;
}
