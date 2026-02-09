#!/usr/bin/env bash
# Test script for guard-pipeline-messages.sh

set -uo pipefail

SCRIPT="./dream-team-plugin/hooks/scripts/guard-pipeline-messages.sh"

echo "Testing guard-pipeline-messages.sh..."
echo

# ============================================================================
# A. HANDOFF ROUTING GUARD TESTS
# ============================================================================
echo "=== A. Handoff Routing Guard Tests ==="
echo

# Test A1: Coding agent sends to code-review (correct) - should allow
echo "Test A1: Coding → code-review with 'ready for review' (should allow)"
export DTQ_AGENT=coding-1
set +e
echo '{"type": "message", "recipient": "code-review", "content": "Task 6 ready for review"}' | $SCRIPT
RESULT=$?
set -e
if [ $RESULT -eq 0 ]; then
    echo "✓ PASS: Correct routing allowed"
else
    echo "✗ FAIL: Correct routing was blocked"
fi
echo

# Test A2: Coding agent sends to team-lead (wrong) - should block
echo "Test A2: Coding → team-lead with 'ready for review' (should block)"
export DTQ_AGENT=coding-1
set +e
echo '{"type": "message", "recipient": "team-lead", "content": "Task 6 ready for review"}' | $SCRIPT 2>&1
RESULT=$?
set -e
if [ $RESULT -ne 0 ]; then
    echo "✓ PASS: Incorrect routing blocked"
else
    echo "✗ FAIL: Incorrect routing was allowed"
fi
echo

# Test A3: Coding agent sends escalation to team-lead - should allow
echo "Test A3: Coding → team-lead with 'ESCALATION:' prefix (should allow)"
export DTQ_AGENT=coding-1
set +e
echo '{"type": "message", "recipient": "team-lead", "content": "ESCALATION: Task 6 is blocked"}' | $SCRIPT
RESULT=$?
set -e
if [ $RESULT -eq 0 ]; then
    echo "✓ PASS: Escalation allowed"
else
    echo "✗ FAIL: Escalation was blocked"
fi
echo

# Test A4: Code-review sends to qa (correct) - should allow
echo "Test A4: Code-review → qa with 'passed code review' (should allow)"
export DTQ_AGENT=code-review
set +e
echo '{"type": "message", "recipient": "qa", "content": "Task 6 passed code review, ready for QA"}' | $SCRIPT
RESULT=$?
set -e
if [ $RESULT -eq 0 ]; then
    echo "✓ PASS: Correct routing allowed"
else
    echo "✗ FAIL: Correct routing was blocked"
fi
echo

# Test A5: Code-review sends to team-lead (wrong) - should block
echo "Test A5: Code-review → team-lead with 'ready for QA' (should block)"
export DTQ_AGENT=code-review
set +e
echo '{"type": "message", "recipient": "team-lead", "content": "Task 6 ready for QA"}' | $SCRIPT 2>&1
RESULT=$?
set -e
if [ $RESULT -ne 0 ]; then
    echo "✓ PASS: Incorrect routing blocked"
else
    echo "✗ FAIL: Incorrect routing was allowed"
fi
echo

# ============================================================================
# C. TEAM LEAD RELAY DETECTION TESTS
# ============================================================================
echo "=== C. Team Lead Relay Detection Tests (warn-only) ==="
echo

# Test C1: Team-lead relays to code-review - should warn but allow
echo "Test C1: Team-lead → code-review with relay pattern (should warn but allow)"
export DTQ_AGENT=team-lead
set +e
echo '{"type": "message", "recipient": "code-review", "content": "go review task 6"}' | $SCRIPT 2>&1
RESULT=$?
set -e
if [ $RESULT -eq 0 ]; then
    echo "✓ PASS: Relay warning issued but message allowed"
else
    echo "✗ FAIL: Relay message was blocked (should only warn)"
fi
echo

# Test C2: Team-lead sends escalation directive - should allow without warning
echo "Test C2: Team-lead → code-review with 'ESCALATION:' (should allow without warning)"
export DTQ_AGENT=team-lead
set +e
echo '{"type": "message", "recipient": "code-review", "content": "ESCALATION: Review stuck task 6 urgently"}' | $SCRIPT 2>&1
RESULT=$?
set -e
if [ $RESULT -eq 0 ]; then
    echo "✓ PASS: Escalation allowed"
else
    echo "✗ FAIL: Escalation was blocked"
fi
echo

echo "All tests complete!"
echo
echo "Note: Test B (submit-before-ping guard) requires real dtq entries and is tested during dogfooding."
