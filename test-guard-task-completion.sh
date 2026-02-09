#!/usr/bin/env bash
# Test script for guard-task-completion.sh

set -uo pipefail

SCRIPT="./dream-team-plugin/hooks/scripts/guard-task-completion.sh"

echo "Testing guard-task-completion.sh..."
echo

# Test 1: Non-completion status update should pass
echo "Test 1: Status != completed (should allow)"
echo '{"taskId": "6", "status": "in_progress"}' | $SCRIPT
if [ $? -eq 0 ]; then
    echo "✓ PASS: Non-completion update allowed"
else
    echo "✗ FAIL: Non-completion update was blocked"
fi
echo

# Test 2: Completion with no taskId should fail
echo "Test 2: Completion without taskId (should block)"
set +e
echo '{"status": "completed"}' | $SCRIPT 2>&1
RESULT=$?
set -e
if [ $RESULT -ne 0 ]; then
    echo "✓ PASS: Missing taskId blocked"
else
    echo "✗ FAIL: Missing taskId was allowed"
fi
echo

# Test 3: Completion for non-existent dtq entry (planning task) should allow
echo "Test 3: Completion for non-existent dtq entry (should allow - planning task)"
echo '{"taskId": "99999", "status": "completed"}' | $SCRIPT
if [ $? -eq 0 ]; then
    echo "✓ PASS: Planning task completion allowed"
else
    echo "✗ FAIL: Planning task completion was blocked"
fi
echo

# Test 4: Completion when dtq stage is "coding" should block
# (We'd need a real dtq entry for this - skip for now unless dtq is set up)
echo "Test 4: Skipped - would require real dtq entry in 'coding' stage"
echo

echo "Basic tests complete!"
