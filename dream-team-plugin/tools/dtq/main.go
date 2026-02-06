package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}
	agent := os.Getenv("DTQ_AGENT")
	if agent == "" {
		agent = "unknown"
	}

	var (
		result interface{}
		err    error
	)

	switch os.Args[1] {
	case "submit":
		result, err = cmdSubmit(os.Args[2:], agent)
	case "claim":
		result, err = cmdClaim(os.Args[2:], agent)
	case "approve":
		result, err = cmdApprove(os.Args[2:], agent)
	case "reject":
		result, err = cmdReject(os.Args[2:], agent)
	case "status":
		result, err = cmdStatus(os.Args[2:])
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
		return nil, fmt.Errorf("usage: dtq submit <task-id> --branch <branch>")
	}
	taskID := args[0]
	branch := flagValue(args[1:], "--branch")
	if branch == "" {
		return nil, fmt.Errorf("--branch is required")
	}
	item, err := Submit(taskID, branch, agent)
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

func exitError(format string, args ...interface{}) {
	msg := fmt.Sprintf(format, args...)
	resp, _ := json.Marshal(map[string]string{"error": msg})
	fmt.Fprintln(os.Stderr, string(resp))
	os.Exit(1)
}

func usage() {
	fmt.Fprintln(os.Stderr, `dtq — Dream Team Queue CLI

Usage:
  dtq submit <task-id> --branch <branch>   Submit work for review
  dtq claim <stage>                         Claim next item (review|qa)
  dtq approve <task-id>                     Approve and advance to next stage
  dtq reject <task-id> --reason <text>      Reject and send back for revision
  dtq status [task-id]                      Show queue (or single item detail)

Environment:
  DTQ_AGENT   Your agent name (default: "unknown")`)
}
