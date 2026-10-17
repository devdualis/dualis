/// Keep in sync with `pubspec.yaml` version (segment before `+`).
const String kInstalledAppSemver = '1.0.0';

int _parsePart(String part) => int.tryParse(part) ?? 0;

/// Returns true if [installed] is strictly older than [minimum].
bool isAppVersionBelowMinimum(String installed, String minimum) {
  final i = installed.split('.').map(_parsePart).toList();
  final m = minimum.split('.').map(_parsePart).toList();
  while (i.length < 3) {
    i.add(0);
  }
  while (m.length < 3) {
    m.add(0);
  }
  for (var n = 0; n < 3; n++) {
    if (i[n] < m[n]) return true;
    if (i[n] > m[n]) return false;
  }
  return false;
}
