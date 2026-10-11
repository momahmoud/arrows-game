#!/bin/bash
set -e
cd /Volumes/Mohamed_EX/Mobile/arrow-escape-main
LOG=/tmp/verify_chunks_master.log
exec >> "$LOG" 2>&1
for n in 2 3 4 5 6 7 8 9 10; do
  echo "========== START CHUNK $n $(date) =========="
  flutter test "test/verify_chunk_${n}_test.dart"
  ec=$?
  echo "========== CHUNK $n EXIT: $ec $(date) =========="
  if [ $ec -ne 0 ]; then
    echo "CHUNK $n test exit non-zero but continuing"
  fi
done
echo "========== ALL CHUNKS DONE $(date) =========="
