package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func main() {
	// Extract --agent flag from anywhere in args, or fall back to env var
	agent, remaining := extractGlobalFlag(os.Args[1:], "--agent")
	if agent == "" {
		agent = os.Getenv("DTQ_AGENT")
	}
	if agent == "" {
		agent = "unknown"
	}

	if len(remaining) < 1 {
		usage()
		os.Exit(1)
	}

	var (
		result interface{}
		err    error
	)

	switch remaining[0] {
	case "submit":
		result, err = cmdSubmit(remaining[1:], agent)
	case "claim":
		result, err = cmdClaim(remaining[1:], agent)
	case "approve":
		result, err = cmdApprove(remaining[1:], agent)
	case "reject":
		result, err = cmdReject(remaining[1:], agent)
	case "status":
		result, err = cmdStatus(remaining[1:])
	case "help", "--help", "-h":
		usage()
		return
	default:
		exitError("unknown command: %s", os.Args[1])
	}

	if err != nil {
		exitError("%s", err)
	}
	out, _ := json.MarshalIndent(result, "", "  ")
	fmt.Println(string(out))
}

func cmdSubmit(args []string, agent string) (interface{}, error) {
	if len(args) < 1 {
		return nil, fmt.Errorf("usage: dtq submit <task-id> --branch <branch> --worktree <path>")
	}
	taskID := args[0]
	branch := flagValue(args[1:], "--branch")
	if branch == "" {
		return nil, fmt.Errorf("--branch is required")
	}
	worktree := flagValue(args[1:], "--worktree")
	if worktree == "" {
		return nil, fmt.Errorf("--worktree is required")
	}
	item, err := Submit(taskID, branch, worktree, agent)
	if err != nil {
		return nil, err
	}
	return map[string]interface{}{
		"taskId":  item.TaskID,
		"stage":   item.Stage,
		"message": "submitted for review",
	}, nil
}

func cmdClaim(args []string, agent string) (interface{}, error) {
	if len(args) < 1 {
		return nil, fmt.Errorf("usage: dtq claim <stage>  (review|qa)")
	}
	item, err := Claim(args[0], agent)
	if err != nil {
		return nil, err
	}
	return map[string]interface{}{
		"taskId":    item.TaskID,
		"stage":     item.Stage,
		"branch":    item.Branch,
		"worktree":  item.Worktree,
		"claimedBy": item.ClaimedBy,
		"cycles":    item.Cycles,
	}, nil
}

func cmdApprove(args []string, agent string) (interface{}, error) {
	if len(args) < 1 {
		return nil, fmt.Errorf("usage: dtq approve <task-id>")
	}
	item, err := Approve(args[0], agent)
	if err != nil {
		return nil, err
	}
	return map[string]interface{}{
		"taskId":  item.TaskID,
		"stage":   item.Stage,
		"message": fmt.Sprintf("advanced to %s", item.Stage),
	}, nil
}

func cmdReject(args []string, agent string) (interface{}, error) {
	if len(args) < 1 {
		return nil, fmt.Errorf("usage: dtq reject <task-id> --reason <text>")
	}
	taskID := args[0]
	reason := flagValue(args[1:], "--reason")
	if reason == "" {
		return nil, fmt.Errorf("--reason is required")
	}
	item, err := Reject(taskID, agent, reason)
	if err != nil {
		return nil, err
	}
	// Build response with escalation warning if needed
	resp := map[string]interface{}{
		"taskId":  item.TaskID,
		"stage":   item.Stage,
		"cycles":  item.Cycles,
		"message": "sent back for revision",
	}
	if item.Cycles >= 3 {
		resp["warning"] = fmt.Sprintf("escalation recommended — %d review cycles", item.Cycles)
	}
	return resp, nil
}

func cmdStatus(args []string) (interface{}, error) {
	taskID := ""
	if len(args) > 0 {
		taskID = args[0]
	}
	return Status(taskID)
}

// flagValue extracts the value for a --flag from args.
func flagValue(args []string, flag string) string {
	for i, a := range args {
		if a == flag && i+1 < len(args) {
			return args[i+1]
		}
		if strings.HasPrefix(a, flag+"=") {
			return strings.TrimPrefix(a, flag+"=")
		}
	}
	return ""
}

// extractGlobalFlag pulls a --flag value from anywhere in args and returns
// the value plus the remaining args with the flag removed.
func extractGlobalFlag(args []string, flag string) (string, []string) {
	var remaining []string
	value := ""
	for i := 0; i < len(args); i++ {
		if args[i] == flag && i+1 < len(args) {
			value = args[i+1]
			i++ // skip the value
		} else if strings.HasPrefix(args[i], flag+"=") {
			value = strings.TrimPrefix(args[i], flag+"=")
		} else {
			remaining = append(remaining, args[i])
		}
	}
	return value, remaining
}

func exitError(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	resp, _ := json.Marshal(map[string]string{"error": msg})
	fmt.Fprintln(os.Stderr, string(resp))
	os.Exit(1)
}

func usage() {
	fmt.Fprintln(os.Stderr, `dtq — Dream Team Queue CLI

Usage:
  dtq submit <task-id> --branch <branch> --worktree <path>   Submit work for review
  dtq claim <stage>                         Claim next item (review|qa)
  dtq approve <task-id>                     Approve and advance to next stage
  dtq reject <task-id> --reason <text>      Reject and send back for revision
  dtq status [task-id]                      Show queue (or single item detail)

Global flags:
  --agent <name>   Your agent name (overrides DTQ_AGENT env var)

Environment (optional, auto-detected when possible):
  DTQ_AGENT       Your agent name (default: "unknown")
  DTQ_QUEUE_DIR   Queue directory (default: auto-detect from git root)`)
}
