// ignore_for_file: avoid_print

@Tags(['generator'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'verify_chunk_helper.dart';

void main() {
  test('Verify levels 801-900 (chunk 9)', () {
    runVerifyChunk(
      startLevel: 801,
      endLevel: 900,
      logFile: 'assets/chunk_9_log.txt',
    );
  });
}
