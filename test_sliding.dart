import 'dart:io';

String _correctOCRDigits(String input) {
    return input
        .replaceAll(RegExp(r'[OoDdQqC]'), '0')
        .replaceAll(RegExp(r'[Il|!\]\[]'), '1')
        .replaceAll(RegExp(r'[Zz]'), '2')
        .replaceAll(RegExp(r'[Aa]'), '4')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Ggb]'), '6')
        .replaceAll(RegExp(r'[Tt]'), '7')
        .replaceAll(RegExp(r'[B]'), '8')
        .replaceAll(RegExp(r'[gP]'), '9'); // P kadang dibaca sebagai 9
}

bool _isValidNomorKK(String nomorKK) {
    if (nomorKK.length != 16) return false;
    if (!RegExp(r'^\d{16}$').hasMatch(nomorKK)) return false;
    // Nomor KK / NIK tidak pernah diawali dengan angka 0
    if (nomorKK.startsWith('0')) return false;
    // Tidak boleh semua angka sama (0000... atau 1111...)
    if (nomorKK.split('').toSet().length == 1) return false;
    return true;
}

void main() {
  final text = 'S A L I N A N No3674061011250011';
  final regex = RegExp(r'(?:[0-9OoIlSZBgbCQD]\s*){16,}', caseSensitive: false);

  final matches = regex.allMatches(text);
  for (final match in matches) {
    final rawMatch = match.group(0)!.replaceAll(RegExp(r'[\s\-]'), '');
    if (rawMatch.length >= 16) {
      for (int j = 0; j <= rawMatch.length - 16; j++) {
        final sub = rawMatch.substring(j, j + 16);
        final raw = _correctOCRDigits(sub);
        if (_isValidNomorKK(raw)) {
           print('FOUND: $raw');
           return;
        }
      }
    }
  }
}
