import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/utils/date_input_formatter.dart';
import 'package:dualis_mobile/features/auth/domain/form_validators.dart';

void main() {
  group('DateInputFormatter Tests', () {
    final formatter = DateInputFormatter();

    TextEditingValue format(String newText, {String oldText = '', int? oldOffset, int? newOffset}) {
      final oldVal = TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldOffset ?? oldText.length),
      );
      final newVal = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset ?? newText.length),
      );
      return formatter.formatEditUpdate(oldVal, newVal);
    }

    test('formats 8 consecutive digits into DD/MM/AAAA mask', () {
      final result = format('14011985');
      expect(result.text, equals('14/01/1985'));
      expect(result.selection.end, equals(10));
    });

    test('formats incremental typing progressively', () {
      // User types 1
      var res = format('1');
      expect(res.text, equals('1'));

      // User types 4 -> 14
      res = format('14', oldText: '1');
      expect(res.text, equals('14'));

      // User types 0 -> 140 becomes 14/0
      res = format('140', oldText: '14');
      expect(res.text, equals('14/0'));

      // User types 1 -> 1401 becomes 14/01
      res = format('14/01', oldText: '14/0');
      expect(res.text, equals('14/01'));

      // User types 1 -> 14011 becomes 14/01/1
      res = format('14/011', oldText: '14/01');
      expect(res.text, equals('14/01/1'));

      // User completes year -> 14/01/1985
      res = format('14/01/1985', oldText: '14/01/198');
      expect(res.text, equals('14/01/1985'));
    });

    test('strips non-numeric characters automatically', () {
      final result = format('14a.01-1985');
      expect(result.text, equals('14/01/1985'));
    });

    test('limits input to max 8 digits (DD/MM/AAAA)', () {
      final result = format('140119859999');
      expect(result.text, equals('14/01/1985'));
    });

    test('handles backspace deletion correctly', () {
      // Deleting last digit
      final res1 = format('14/01/198', oldText: '14/01/1985');
      expect(res1.text, equals('14/01/198'));

      // Deleting when cursor hits slash
      final res2 = format('14/0', oldText: '14/01');
      expect(res2.text, equals('14/0'));
    });
  });

  group('FormValidators.validateDateOfBirth with mask and raw digits', () {
    test('validates standard masked format DD/MM/AAAA', () {
      expect(FormValidators.validateDateOfBirth('14/01/1985'), isNull);
      expect(FormValidators.validateDateOfBirth('20/05/2000'), isNull);
    });

    test('validates unmasked 8 raw digits DDMMAAAA gracefully', () {
      expect(FormValidators.validateDateOfBirth('14011985'), isNull);
    });

    test('rejects impossible dates like 31/02/1985', () {
      expect(FormValidators.validateDateOfBirth('31/02/1985'), equals('Informe uma data de nascimento válida.'));
      expect(FormValidators.validateDateOfBirth('31021985'), equals('Informe uma data de nascimento válida.'));
    });

    test('rejects future dates', () {
      final futureYear = DateTime.now().year + 1;
      expect(
        FormValidators.validateDateOfBirth('01/01/$futureYear'),
        equals('A data de nascimento não pode estar no futuro.'),
      );
    });

    test('rejects age under 13', () {
      final recentYear = DateTime.now().year - 5;
      expect(
        FormValidators.validateDateOfBirth('01/01/$recentYear'),
        equals('Você deve ter pelo menos 13 anos para criar uma conta.'),
      );
    });
  });
}
