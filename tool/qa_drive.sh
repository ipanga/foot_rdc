#!/bin/bash
# Runs one integration test on a device with a hard time limit. usage: qa_drive.sh <device> <target> <screens-dir> <log> [seconds]
DEVICE=$1; TARGET=$2; SCREENS=$3; LOG=$4; LIMIT=${5:-900}
export QA_SCREENS_DIR=$SCREENS
perl -e 'alarm shift; exec @ARGV' "$LIMIT" flutter drive -d "$DEVICE" --driver=test_driver/integration_test.dart --target="$TARGET" > "$LOG" 2>&1
rc=$?; [ $rc -eq 142 ] && echo "TIMEOUT after ${LIMIT}s" >> "$LOG"; echo "rc=$rc $(grep -E 'All tests passed|Some tests failed|TIMEOUT' "$LOG" | tail -1)"
