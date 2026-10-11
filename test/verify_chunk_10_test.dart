// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'verify_chunk_helper.dart';

void main() {
  test('Verify levels 901-1000 (chunk 10)', () {
    runVerifyChunk(
      startLevel: 901,
      endLevel: 1000,
      logFile: 'assets/chunk_10_log.txt',
    );
  });
}
