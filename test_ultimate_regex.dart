import 'dart:io';

void main() {
  final text1 = 'KARTU KELUARGA No. 3674061011250011 Nama Kepala Keluarga';
  final text2 = 'S A L I N A N No3674061011250011';
  final text3 = 'No.3674O6l0112S0011';
  final text4 = 'No. 36740610 11250011';

  final regex = RegExp(r'(?:[0-9OoIlSZBgbCQD]\s*){16,}', caseSensitive: false);

  for (final text in [text1, text2, text3, text4]) {
    final match = regex.firstMatch(text);
    if (match != null) {
      final rawMatch = match.group(0)!.replaceAll(RegExp(r'[\s\-]'), '');
      print('Original: $text');
      print('Matched: $rawMatch');
    } else {
      print('Failed: $text');
    }
  }
}
