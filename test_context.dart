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
    if (nomorKK.startsWith('0')) return false;
    if (nomorKK.split('').toSet().length == 1) return false;
    return true;
}

void main() {
  // Simulate image rotated 90 degrees (scanned left-to-right)
  final text = '1 MUHAMMAD NAUFAL 3174072301990007 \n KARTU KELUARGA \n S A L I N A N \n No. \n 3674O61011250011 \n 3174072301990007';
  
  final patterns = [
    RegExp(r'(?:No\.?\s*(?:KK)?|KARTU\s*KELUARGA)[\s\S]{0,80}?((?:[0-9OoIlSZBgbCQD]\s*){16,})', caseSensitive: false),
    RegExp(r'(?:[0-9OoIlSZBgbCQD]\s*){16,}'),
  ];

  for (final pattern in patterns) {
    final matches = pattern.allMatches(text);
    for (final match in matches) {
      final rawMatch = match.group(1) != null ? match.group(1)! : match.group(0)!;
      final cleanedMatch = rawMatch.replaceAll(RegExp(r'[\s\-]'), '');
      
      if (cleanedMatch.length >= 16) {
        for (int j = 0; j <= cleanedMatch.length - 16; j++) {
          final sub = cleanedMatch.substring(j, j + 16);
          final raw = _correctOCRDigits(sub);
          if (_isValidNomorKK(raw)) {
             print('FOUND with pattern: $raw');
             return;
          }
        }
      }
    }
  }
}
