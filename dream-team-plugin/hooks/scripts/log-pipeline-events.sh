#!/usr/bin/env bash
# log-pipeline-events.sh — PostToolUse hook for dogfooding observability
# Logs pipeline-relevant events to .dtq/pipeline-events.log in JSONL format

set -euo pipefail

# Read tool use input from stdin
TOOL_INPUT=$(cat)

# Extract tool name from the first line of input (format: "tool: <name>")
TOOL_NAME=$(echo "$TOOL_INPUT" | grep -m1 "^tool:" | sed 's/^tool: //' || echo "")

# Log file location
LOG_FILE=".dtq/pipeline-events.log"

# Ensure .dtq directory exists
mkdir -p .dtq

# Get current timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get agent name from environment (defaults to "unknown" if not set)
AGENT="${DTQ_AGENT:-unknown}"

# Function to append event to log file
log_event() {
    local event="$1"
    echo "$event" >> "$LOG_FILE"
}

# Handle Bash tool events (dtq commands)
if [[ "$TOOL_NAME" == "Bash" ]]; then
    # Extract command from input
    COMMAND=$(echo "$TOOL_INPUT" | grep -A1 "^command:" | tail -n1 | sed 's/^[[:space:]]*//' || echo "")

    # dtq submit
    if echo "$COMMAND" | grep -q "dtq submit"; then
        TASK_ID=$(echo "$COMMAND" | grep -oE "dtq submit [0-9]+" | grep -oE "[0-9]+" || echo "")
        if [[ -n "$TASK_ID" ]]; then
            log_event "{\"type\":\"dtq-submit\",\"taskId\":\"$TASK_ID\",\"agent\":\"$AGENT\",\"timestamp\":\"$TIMESTAMP\"}"
        fi
    fi

    # dtq claim
    if echo "$COMMAND" | grep -q "dtq claim"; then
        STAGE=$(echo "$COMMAND" | grep -oE "dtq claim (review|qa)" | awk '{print $3}' || echo "")
        # We'll check success from the tool result (not available in PostToolUse input)
        # For now, log claim attempt - success will be inferred from presence of subsequent events
        if [[ -n "$STAGE" ]]; then
            log_event "{\"type\":\"dtq-claim\",\"stage\":\"$STAGE\",\"agent\":\"$AGENT\",\"timestamp\":\"$TIMESTAMP\"}"
        fi
    fi

    # dtq approve
    if echo "$COMMAND" | grep -q "dtq approve"; then
        TASK_ID=$(echo "$COMMAND" | grep -oE "dtq approve [0-9]+" | grep -oE "[0-9]+" || echo "")
        if [[ -n "$TASK_ID" ]]; then
            log_event "{\"type\":\"dtq-approve\",\"taskId\":\"$TASK_ID\",\"agent\":\"$AGENT\",\"timestamp\":\"$TIMESTAMP\"}"
        fi
    fi

    # dtq reject
    if echo "$COMMAND" | grep -q "dtq reject"; then
        TASK_ID=$(echo "$COMMAND" | grep -oE "dtq reject [0-9]+" | grep -oE "[0-9]+" || echo "")
        if [[ -n "$TASK_ID" ]]; then
            # Cycles would need to be extracted from dtq output, which we don't have in PostToolUse
            # For now, log without cycles - can be enriched later from dtq status queries
            log_event "{\"type\":\"dtq-reject\",\"taskId\":\"$TASK_ID\",\"agent\":\"$AGENT\",\"timestamp\":\"$TIMESTAMP\"}"
        fi
    fi
fi

# Handle SendMessage tool events (handoff pings)
if [[ "$TOOL_NAME" == "SendMessage" ]]; then
    # Extract recipient and content from input
    RECIPIENT=$(echo "$TOOL_INPUT" | grep "^recipient:" | sed 's/^recipient: //' || echo "")
    CONTENT=$(echo "$TOOL_INPUT" | sed -n '/^content:/,/^[a-z]*:/p' | grep -v "^content:" | grep -v "^[a-z]*:" || echo "")

    # Check if content matches handoff patterns
    HANDOFF_PATTERN="ready for review|resubmitted|passed.*review|ready for QA|merge-ready|failed.*QA"
    if echo "$CONTENT" | grep -qiE "$HANDOFF_PATTERN"; then
        # Try to extract task ID from content (pattern: "Task {id}" or "task {id}")
        TASK_ID=$(echo "$CONTENT" | grep -oiE "(task|#)[[:space:]]*[0-9]+" | grep -oE "[0-9]+" | head -n1 || echo "")

        if [[ -n "$RECIPIENT" ]]; then
            log_event "{\"type\":\"handoff-ping\",\"sender\":\"$AGENT\",\"recipient\":\"$RECIPIENT\",\"taskId\":\"$TASK_ID\",\"timestamp\":\"$TIMESTAMP\"}"
        fi
    fi
fi

# Handle TaskUpdate tool events (task completions)
if [[ "$TOOL_NAME" == "TaskUpdate" ]]; then
    # Extract taskId and status from input
    TASK_ID=$(echo "$TOOL_INPUT" | grep "^taskId:" | sed 's/^taskId: //' || echo "")
    STATUS=$(echo "$TOOL_INPUT" | grep "^status:" | sed 's/^status: //' || echo "")

    if [[ "$STATUS" == "completed" ]] && [[ -n "$TASK_ID" ]]; then
        log_event "{\"type\":\"task-completed\",\"taskId\":\"$TASK_ID\",\"agent\":\"$AGENT\",\"timestamp\":\"$TIMESTAMP\"}"
    fi
fi

# Exit successfully (this is a passive logger, never blocks)
exit 0
