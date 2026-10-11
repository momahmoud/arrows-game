// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'verify_chunk_helper.dart';

void main() {
  test('Verify levels 501-600 (chunk 6)', () {
    runVerifyChunk(
      startLevel: 501,
      endLevel: 600,
      logFile: 'assets/chunk_6_log.txt',
    );
  });
}
