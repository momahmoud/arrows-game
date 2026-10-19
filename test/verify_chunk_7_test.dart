// ignore_for_file: avoid_print

@Tags(['generator'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'verify_chunk_helper.dart';

void main() {
  test('Verify levels 601-700 (chunk 7)', () {
    runVerifyChunk(
      startLevel: 601,
      endLevel: 700,
      logFile: 'assets/chunk_7_log.txt',
    );
  });
}
