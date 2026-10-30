import 'package:dualis_mobile/features/care/domain/care_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
