#!/usr/bin/env bash
# guard-pipeline-messages.sh
# PreToolUse hook for SendMessage that enforces distributed pipeline protocol.
#
# Combines three enforcement checks:
# A. Handoff routing guard - block mis-routed pipeline handoffs
# B. Submit-before-ping guard - block review pings before dtq submit
# C. Team Lead relay detection - warn on team-lead relay patterns

set -euo pipefail

# Read tool input from stdin
TOOL_INPUT=$(cat)

# Extract fields from JSON
if command -v jq &>/dev/null; then
    RECIPIENT=$(echo "$TOOL_INPUT" | jq -r '.recipient // empty')
    CONTENT=$(echo "$TOOL_INPUT" | jq -r '.content // empty')
    TYPE=$(echo "$TOOL_INPUT" | jq -r '.type // empty')
else
    # Fallback: extract using grep/sed
    RECIPIENT=$(echo "$TOOL_INPUT" | grep -o '"recipient"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"recipient"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
    CONTENT=$(echo "$TOOL_INPUT" | grep -o '"content"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"content"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
    TYPE=$(echo "$TOOL_INPUT" | grep -o '"type"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
fi

# Get sender agent from environment variable
SENDER="${DTQ_AGENT:-unknown}"

# If content starts with "ESCALATION:", always allow (legitimate escalation path)
if echo "$CONTENT" | grep -q "^ESCALATION:"; then
    exit 0
fi

# ============================================================================
# A. HANDOFF ROUTING GUARD
# ============================================================================
# Block coding agents from sending handoffs to team-lead instead of code-review
if echo "$SENDER" | grep -q "^coding"; then
    if echo "$CONTENT" | grep -Eiq "ready for review|resubmitted|task [0-9]+ (ready|resubmit)"; then
        if [ "$RECIPIENT" = "team-lead" ]; then
            echo "Routing error: pipeline handoff for 'ready for review' should go to 'code-review', not 'team-lead'." >&2
            echo "Escalations to team-lead must include 'ESCALATION:' prefix." >&2
            exit 1
        fi
    fi
fi

# Block code-review agents from sending handoffs to team-lead instead of qa
if echo "$SENDER" | grep -q "^code-review"; then
    if echo "$CONTENT" | grep -Eiq "passed code review|ready for QA|task [0-9]+ (passed|ready for qa)"; then
        if [ "$RECIPIENT" = "team-lead" ]; then
            echo "Routing error: pipeline handoff for 'ready for QA' should go to 'qa', not 'team-lead'." >&2
            echo "Escalations to team-lead must include 'ESCALATION:' prefix." >&2
            exit 1
        fi
    fi
fi

# ============================================================================
# B. SUBMIT-BEFORE-PING GUARD
# ============================================================================
# If coding agent is pinging code-review, verify task is in dtq review stage
if echo "$SENDER" | grep -q "^coding"; then
    if [ "$RECIPIENT" = "code-review" ]; then
        if echo "$CONTENT" | grep -Eiq "ready for review|resubmitted"; then
            # Extract task ID from content (pattern: "Task #6" or "task 6")
            TASK_ID=$(echo "$CONTENT" | grep -Eio "task #?[0-9]+" | head -1 | grep -Eo "[0-9]+" || echo "")

            if [ -n "$TASK_ID" ]; then
                # Find dtq binary
                DTQ_BIN=""
                if command -v dtq &>/dev/null; then
                    DTQ_BIN="dtq"
                elif [ -f "/Users/chrismck/tasks/claude-dream-team/dream-team-plugin/tools/dtq/dtq" ]; then
                    DTQ_BIN="/Users/chrismck/tasks/claude-dream-team/dream-team-plugin/tools/dtq/dtq"
                elif [ -f "${CLAUDE_PLUGIN_ROOT}/tools/dtq/dtq" ]; then
                    DTQ_BIN="${CLAUDE_PLUGIN_ROOT}/tools/dtq/dtq"
                fi

                # If dtq is available, check if task is in review stage
                if [ -n "$DTQ_BIN" ] && [ -x "$DTQ_BIN" ]; then
                    DTQ_OUTPUT=$($DTQ_BIN status "$TASK_ID" 2>/dev/null || echo "")

                    # Only block if we can confirm the task exists but is NOT in review stage
                    # If task doesn't exist in dtq yet, allow (might be first submit)
                    if [ -n "$DTQ_OUTPUT" ]; then
                        # Check if stage is "review"
                        if command -v jq &>/dev/null; then
                            STAGE=$(echo "$DTQ_OUTPUT" | jq -r '.stage // empty')
                        else
                            STAGE=$(echo "$DTQ_OUTPUT" | grep -o '"stage"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"stage"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
                        fi

                        # Block only if task exists but is in wrong stage (e.g., "coding")
                        if [ -n "$STAGE" ] && [ "$STAGE" != "review" ]; then
                            echo "You must run 'dtq submit' before sending a review ping. Task $TASK_ID is in stage '$STAGE', not 'review'." >&2
                            exit 1
                        fi
                    fi
                    # If DTQ_OUTPUT is empty (task not in dtq), allow - this might be the first ping after submit
                fi
            fi
        fi
    fi
fi

# ============================================================================
# C. TEAM LEAD RELAY DETECTION (WARN ONLY)
# ============================================================================
if [ "$SENDER" = "team-lead" ]; then
    if [ "$RECIPIENT" = "code-review" ] || [ "$RECIPIENT" = "qa" ]; then
        # Check for relay patterns
        if echo "$CONTENT" | grep -Eiq "review task|go review|check the queue|ready for review|needs review|validate task|run QA|ready for QA|check for QA"; then
            echo "WARNING: This looks like a pipeline relay. In the distributed model, upstream agents ping downstream agents directly." >&2
            echo "If you're relaying because the upstream agent failed to ping, consider messaging the upstream agent to resend their ping instead." >&2
            # Don't exit 1 - this is a warning, not a block
        fi
    fi
fi

# If we got here, the message is allowed
exit 0
