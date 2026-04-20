#!/bin/bash

TESTS_DIR="tests"
OUTPUT_DIR="output"

mkdir -p "$OUTPUT_DIR"

pass=0
fail=0

for f in "$TESTS_DIR"/*.cpp; do
    [ -e "$f" ] || { echo "No test files found in $TESTS_DIR/"; exit 1; }

    name=$(basename "$f" .cpp)
    quads_out="$OUTPUT_DIR/${name}_quads.txt"
    errors_out="$OUTPUT_DIR/${name}_errors.txt"

    ./bas.exe "$quads_out" "$errors_out" < "$f"
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "[PASS] $name"
        pass=$((pass + 1))
    else
        echo "[FAIL] $name  (exit $exit_code)"
        fail=$((fail + 1))
    fi
done

echo ""
echo "Results: $pass passed, $fail failed"
