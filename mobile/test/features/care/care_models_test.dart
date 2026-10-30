import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exam numbers keep unambiguous decimal values in either format', () {
    for (final (printed, number) in [
      ('0.125', 0.125),
      ('0,125', 0.125),
      ('0.13', 0.13),
      ('13,8', 13.8),
      ('13.8', 13.8),
      ('1250', 1250.0),
      ('1.234,56', 1234.56),
      ('1,234.56', 1234.56),
      ('1.234.567', 1234567.0),
      ('1,234,567', 1234567.0),
    ]) {
      expect(examNumber(printed), number, reason: printed);
    }
  });

  test('exam numbers omit ambiguous separators and nonnumeric results', () {
    for (final printed in ['1.234', '1,234', '245.000', '245,000', '1,2,3', '1..2', '< 5', 'Não reagente', '']) {
      expect(examNumber(printed), isNull, reason: printed);
    }
    final value = ExamValue.fromJson({'item': 'Glucose', 'value': '1.234', 'confirmed': true});
    expect(value.toJson()['value'], '1.234');
  });

  test('exam item names are written one way', () {
    expect(tidyExamName('SEGMENTADOS :'), 'Segmentados');
    expect(tidyExamName('Segmentados:'), 'Segmentados');
    expect(tidyExamName('* Leucócitos ...'), 'Leucócitos');
    expect(tidyExamName('TEMPO DE PROTROMBINA'), 'Tempo de protrombina');
    expect(tidyExamName('COLESTEROL HDL'), 'Colesterol HDL');
    expect(tidyExamName('VCM'), 'VCM');
    expect(tidyExamName('T4 LIVRE'), 'T4 livre');
    expect(tidyExamName('Hemoglobina glicada (HbA1c)'), 'Hemoglobina glicada (HbA1c)');
    final v = ExamValue.fromJson({'section': 'HEMOGRAMA', 'item': 'Segmentados :', 'value': '60'});
    expect((v.section, v.item), ('Hemograma', 'Segmentados'));
  });
}
