// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'verify_chunk_helper.dart';

void main() {
  test('Verify levels 701-800 (chunk 8)', () {
    runVerifyChunk(
      startLevel: 701,
      endLevel: 800,
      logFile: 'assets/chunk_8_log.txt',
    );
  });
}
