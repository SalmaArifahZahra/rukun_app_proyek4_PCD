import 'dart:io';

String _correctOCRDigits(String input) {
    return input
        .replaceAll(RegExp(r'[OoDdQqC]'), '0')
        .replaceAll(RegExp(r'[IlL|!\]\[]'), '1')
        .replaceAll(RegExp(r'[Zz]'), '2')
        .replaceAll(RegExp(r'[Aa]'), '4')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Ggb]'), '6')
        .replaceAll(RegExp(r'[Tt]'), '7')
        .replaceAll(RegExp(r'[B]'), '8')
        .replaceAll(RegExp(r'[gP]'), '9'); // P kadang dibaca sebagai 9
}

bool _isValidNomorKK(String s) {
    if (s.length != 16) return false;
    if (!RegExp(r'^\d{16}$').hasMatch(s)) return false;
    if (s.startsWith('0')) return false;
    return s.split('').toSet().length > 1;
}

void main() {
  final text = '''
KARTU KELUARGA
No. 3L74051011250011
MUHAMMAD NAUFAL MUHARRAM
:JL. CEMPEDAK I BLOK G.9 NO. 1
Nama Kepala Keluarga
DesaKelurahan :PAMULANG TIMUR
Kecamatan :PAMULANG
Alamat
Dpatenvkota
ANGERANG SELATAN
DANITE
REPUBLIK INDONESIA
:15436
de Pos
Golongan
Darah
Tanggal
Lahir
(5)
23-01.1999
Jenis
Kelamin
Jenis Pekerjaan
Nama Lengkap
Tempat Lahir
Pendidikan
Agama
No
NIK
(3)
3174072301990007 KLAKIKARTA
3573014508990002 PEREMPUAN JAKARTA
''';
  
  final cleaned = text.replaceAll('\n', ' ');
  
  final patterns = [
    RegExp(r'(?:No\.?\s*(?:KK)?|KARTU\s*KELUARGA)[\s\S]{0,80}?((?:[0-9A-Za-z]\s*){16,})', caseSensitive: false),
    RegExp(r'(?:[0-9OoIlLSZBgbCQD]\s*){16,}'),
  ];

  for (final pattern in patterns) {
    print('Testing pattern: \${pattern.pattern}');
    final matches = pattern.allMatches(cleaned);
    for (final match in matches) {
      final rawMatch = match.groupCount >= 1 && match.group(1) != null 
          ? match.group(1)! 
          : match.group(0)!;
          
      final cleanedMatch = rawMatch.replaceAll(RegExp(r'[\s\-]'), '');
      print('Found match: \$cleanedMatch');
      
      if (cleanedMatch.length >= 16) {
        for (int j = 0; j <= cleanedMatch.length - 16; j++) {
          final sub = cleanedMatch.substring(j, j + 16);
          final raw = _correctOCRDigits(sub);
          if (_isValidNomorKK(raw)) {
             print('VALID KK: \$raw');
             return;
          } else {
             print('Invalid KK: \$raw');
          }
        }
      }
    }
  }
}
