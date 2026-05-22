import 'dart:io';

void main() {
  final rawText = 'KARTU KELUARGA No. 3674061011250011 Nama Kepala Keluarga';
  final cleaned = rawText.replaceAll('\n', ' ');
  
  final pattern1 = RegExp(r'(?:No\.?\s*(?:KK)?|KARTU\s*KELUARGA)(?:\s*No\.?)?\s*[:\.\s]*((?:[0-9A-Za-z]\s*){16})', caseSensitive: false);
  
  final matches = pattern1.allMatches(cleaned);
  print('Matches found: ${matches.length}');
  for (final match in matches) {
    print('Match group 0: ${match.group(0)}');
    print('Match group 1: ${match.group(1)}');
    final rawMatch = match.group(1)!.replaceAll(RegExp(r'[\s\-]'), '');
    print('Raw match: $rawMatch');
    print('Is 16 digits? ${RegExp(r"^\d{16}$").hasMatch(rawMatch)}');
  }
}
