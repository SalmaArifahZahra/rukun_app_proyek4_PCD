import 'dart:io';
import 'lib/services/pcd/kk_ocr_engine.dart';

void main() {
  final text = 'No.  3674061011250011';
  final result = KKFieldParser.parseNomorKK(text);
  print('Result for "$text": found=${result.isFound}, value=${result.value}, confidence=${result.confidence}');
  
  final nikText = '3174072301990007';
  final nikResult = KKFieldParser.parseNomorKK(nikText);
  print('Result for "$nikText": found=${nikResult.isFound}, value=${nikResult.value}, confidence=${nikResult.confidence}');
}
