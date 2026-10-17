import 'package:flutter_test/flutter_test.dart';
import 'package:dualis_mobile/core/safety/emergency_numbers.dart';

List<String> numbers(String? region) =>
    EmergencyNumbers.forRegion(region).all.map((l) => l.number).toList();

void main() {
  test('Brazil: SAMU 192, CVV 188, Bombeiros 193, Polícia 190', () {
    expect(numbers('BR'), ['192', '188', '193', '190']);
    expect(numbers('br'), ['192', '188', '193', '190']);
  });

  test('United States: 911 and 988', () => expect(numbers('US'), ['911', '988']));
  test('Spain: 112 and 024', () => expect(numbers('ES'), ['112', '024']));
  test('Portugal: 112 and SNS 24', () => expect(numbers('PT'), ['112', '808 24 24 24']));
  test('Mexico: 911 first', () => expect(numbers('MX').first, '911'));

  test('EU countries use 112', () {
    for (final code in ['FR', 'DE', 'IT', 'PL', 'SE']) {
      expect(EmergencyNumbers.forRegion(code).emergency.number, '112', reason: code);
      expect(EmergencyNumbers.forRegion(code).isFallback, isFalse, reason: code);
    }
  });

  test('unknown or missing region falls back to 112', () {
    for (final code in [null, 'ZZ', 'JP']) {
      final lines = EmergencyNumbers.forRegion(code);
      expect(lines.emergency.number, '112');
      expect(lines.isFallback, isTrue);
    }
  });

  test('dialable strips spaces', () {
    expect(EmergencyNumbers.forRegion('PT').others.first.dialable, '808242424');
  });
}
