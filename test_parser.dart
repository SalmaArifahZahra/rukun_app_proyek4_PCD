import 'dart:io';
import 'lib/services/pcd/kk_ocr_engine.dart';

void main() {
  print('Testing Nomor KK...');
  try {
    final res = KKFieldParser.parseNomorKK('KARTU KELUARGA No. 3674061011250011');
    print('Nomor KK: ${res.value}');
  } catch (e, st) {
    print('Crash in Nomor KK: $e\n$st');
  }

  print('Testing Kode Pos...');
  try {
    final res = KKFieldParser.parseKodePos('Kode Pos : 15436');
    print('Kode Pos: ${res.value}');
  } catch (e, st) {
    print('Crash in Kode Pos: $e\n$st');
  }

  print('Testing RT RW...');
  try {
    final res = KKFieldParser.parseRTRW('RT/RW : 006/013');
    print('RT RW: ${res.value}');
  } catch (e, st) {
    print('Crash in RT RW: $e\n$st');
  }
}
