#!/usr/bin/env bash
# guard-task-completion.sh
# PreToolUse hook for TaskUpdate that prevents tasks from being marked completed
# before dtq shows them as merge-ready.

set -euo pipefail

# Read tool input from stdin
TOOL_INPUT=$(cat)

# Parse the status field from the JSON input
# Using jq if available, fallback to grep/sed if not
if command -v jq &>/dev/null; then
    STATUS=$(echo "$TOOL_INPUT" | jq -r '.status // empty')
else
    # Fallback: extract status using grep/sed
    STATUS=$(echo "$TOOL_INPUT" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
fi

# If status is not being set to "completed", allow the update
if [ "$STATUS" != "completed" ]; then
    exit 0
fi

# Extract taskId from the JSON input
if command -v jq &>/dev/null; then
    TASK_ID=$(echo "$TOOL_INPUT" | jq -r '.taskId // empty')
else
    # Fallback: extract taskId using grep/sed
    TASK_ID=$(echo "$TOOL_INPUT" | grep -o '"taskId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"taskId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
fi

# If we couldn't extract a taskId, something is wrong - block with an error
if [ -z "$TASK_ID" ]; then
    echo "ERROR: Could not extract taskId from TaskUpdate input" >&2
    exit 1
fi

# Check dtq status for this task
# dtq may not be in PATH, so try common locations
DTQ_BIN=""
if command -v dtq &>/dev/null; then
    DTQ_BIN="dtq"
elif [ -f "/Users/chrismck/tasks/claude-dream-team/dream-team-plugin/tools/dtq/dtq" ]; then
    DTQ_BIN="/Users/chrismck/tasks/claude-dream-team/dream-team-plugin/tools/dtq/dtq"
elif [ -f "${CLAUDE_PLUGIN_ROOT}/tools/dtq/dtq" ]; then
    DTQ_BIN="${CLAUDE_PLUGIN_ROOT}/tools/dtq/dtq"
else
    # dtq not found - this might be a planning task that never entered dtq, so allow
    exit 0
fi

# Run dtq status and capture output
DTQ_OUTPUT=$($DTQ_BIN status "$TASK_ID" 2>/dev/null || echo "")

# If dtq status returns empty (task not in dtq), allow completion
# This handles planning tasks that never go through the pipeline
if [ -z "$DTQ_OUTPUT" ]; then
    exit 0
fi

# Parse the stage from dtq output
if command -v jq &>/dev/null; then
    STAGE=$(echo "$DTQ_OUTPUT" | jq -r '.stage // empty')
else
    # Fallback: extract stage using grep/sed
    STAGE=$(echo "$DTQ_OUTPUT" | grep -o '"stage"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"stage"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
fi

# If stage is merge-ready, allow completion
if [ "$STAGE" = "merge-ready" ]; then
    exit 0
fi

# Otherwise, block with an error message
echo "Cannot mark task as completed — dtq stage is '$STAGE', must be 'merge-ready'" >&2
exit 1
