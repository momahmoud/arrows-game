import 'package:flutter_test/flutter_test.dart';
import 'verify_chunk_helper.dart';

void main() {
  test('Sample campaign levels verify', () {
    for (final n in [4, 5, 10, 25, 50, 100]) {
      final result = verifyLevel(n);
      expect(
        result['status'],
        'pass',
        reason: 'Level $n: ${result['errors']}',
      );
    }
  });
}
