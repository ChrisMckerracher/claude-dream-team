package main

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"syscall"
	"time"
)

// Data types

type HistoryEntry struct {
	Action string `json:"action"`
	Agent  string `json:"agent"`
	At     string `json:"at"`
	Note   string `json:"note,omitempty"`
}

type QueueItem struct {
	TaskID      string         `json:"taskId"`
	Stage       string         `json:"stage"`
	Branch      string         `json:"branch"`
	ClaimedBy   string         `json:"claimedBy,omitempty"`
	Cycles      int            `json:"cycles"`
	SubmittedAt string         `json:"submittedAt"`
	UpdatedAt   string         `json:"updatedAt"`
	History     []HistoryEntry `json:"history"`
}

type Queue struct {
	Items map[string]*QueueItem `json:"items"`
}

// StatusResponse is the full-queue response shape.
type StatusResponse struct {
	Items  []*QueueItem   `json:"items"`
	Counts map[string]int `json:"counts"`
}

// File I/O with locking

const storePath = ".dtq/queue.json"
const storeDir = ".dtq"

func withLock(fn func(*Queue) error) error {
	if err := os.MkdirAll(storeDir, 0755); err != nil {
		return fmt.Errorf("cannot create %s: %w", storeDir, err)
	}
	f, err := os.OpenFile(storePath, os.O_RDWR|os.O_CREATE, 0644)
	if err != nil {
		return fmt.Errorf("cannot open %s: %w", storePath, err)
	}
	defer f.Close()

	if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX); err != nil {
		return fmt.Errorf("cannot lock %s: %w", storePath, err)
	}
	defer syscall.Flock(int(f.Fd()), syscall.LOCK_UN)

	var q Queue
	info, err := f.Stat()
	if err != nil {
		return fmt.Errorf("cannot stat %s: %w", storePath, err)
	}
	if info.Size() > 0 {
		if err := json.NewDecoder(f).Decode(&q); err != nil {
			return fmt.Errorf("corrupt queue file: %w", err)
		}
	}
	if q.Items == nil {
		q.Items = make(map[string]*QueueItem)
	}

	if err := fn(&q); err != nil {
		return err
	}

	// Atomic write: write to temp file, then rename over the original
	tmp, err := os.CreateTemp(storeDir, "queue-*.json.tmp")
	if err != nil {
		return fmt.Errorf("cannot create temp file: %w", err)
	}
	enc := json.NewEncoder(tmp)
	enc.SetIndent("", "  ")
	if err := enc.Encode(&q); err != nil {
		tmp.Close()
		os.Remove(tmp.Name())
		return fmt.Errorf("cannot write queue: %w", err)
	}
	if err := tmp.Close(); err != nil {
		os.Remove(tmp.Name())
		return err
	}
	if err := os.Rename(tmp.Name(), storePath); err != nil {
		os.Remove(tmp.Name())
		return fmt.Errorf("cannot rename temp file: %w", err)
	}
	return nil
}

func now() string {
	return time.Now().UTC().Format(time.RFC3339)
}

// Submit creates or re-submits an item for review.
func Submit(taskID, branch, agent string) (*QueueItem, error) {
	var result *QueueItem
	err := withLock(func(q *Queue) error {
		item, exists := q.Items[taskID]
		if exists && item.Stage != "coding" {
			return fmt.Errorf("task %s is in stage '%s', can only submit from 'coding'", taskID, item.Stage)
		}
		t := now()
		if !exists {
			item = &QueueItem{
				TaskID:      taskID,
				Branch:      branch,
				Cycles:      0,
				SubmittedAt: t,
				History:     []HistoryEntry{},
			}
			q.Items[taskID] = item
		}
		item.Stage = "review"
		item.Branch = branch
		item.ClaimedBy = ""
		item.UpdatedAt = t
		item.History = append(item.History, HistoryEntry{
			Action: "submit",
			Agent:  agent,
			At:     t,
		})
		result = item
		return nil
	})
	return result, err
}

// Claim finds the highest-priority unclaimed item in the given stage.
// Priority: revisions first (cycles > 0), then FIFO by submittedAt.
func Claim(stage, agent string) (*QueueItem, error) {
	if stage != "review" && stage != "qa" {
		return nil, fmt.Errorf("can only claim from 'review' or 'qa', got '%s'", stage)
	}
	var result *QueueItem
	err := withLock(func(q *Queue) error {
		var candidates []*QueueItem
		for _, item := range q.Items {
			if item.Stage == stage && item.ClaimedBy == "" {
				candidates = append(candidates, item)
			}
		}
		if len(candidates) == 0 {
			return fmt.Errorf("no unclaimed items in stage '%s'", stage)
		}
		sort.Slice(candidates, func(i, j int) bool {
			// Revisions first (cycles > 0 before cycles == 0)
			iRev := candidates[i].Cycles > 0
			jRev := candidates[j].Cycles > 0
			if iRev != jRev {
				return iRev
			}
			// Then FIFO by submittedAt
			return candidates[i].SubmittedAt < candidates[j].SubmittedAt
		})
		pick := candidates[0]
		t := now()
		pick.ClaimedBy = agent
		pick.UpdatedAt = t
		pick.History = append(pick.History, HistoryEntry{
			Action: "claim",
			Agent:  agent,
			At:     t,
		})
		result = pick
		return nil
	})
	return result, err
}

// Approve advances an item to the next stage.
func Approve(taskID, agent string) (*QueueItem, error) {
	var result *QueueItem
	err := withLock(func(q *Queue) error {
		item, exists := q.Items[taskID]
		if !exists {
			return fmt.Errorf("task %s not found in queue", taskID)
		}
		var nextStage string
		switch item.Stage {
		case "review":
			nextStage = "qa"
		case "qa":
			nextStage = "merge-ready"
		default:
			return fmt.Errorf("cannot approve task %s in stage '%s'", taskID, item.Stage)
		}
		if item.ClaimedBy == "" {
			return fmt.Errorf("task %s is not claimed — claim it first", taskID)
		}
		t := now()
		item.Stage = nextStage
		item.ClaimedBy = ""
		item.UpdatedAt = t
		item.History = append(item.History, HistoryEntry{
			Action: "approve",
			Agent:  agent,
			At:     t,
		})
		result = item
		return nil
	})
	return result, err
}

// Reject sends an item back to coding and increments cycles.
func Reject(taskID, agent, reason string) (*QueueItem, error) {
	var result *QueueItem
	err := withLock(func(q *Queue) error {
		item, exists := q.Items[taskID]
		if !exists {
			return fmt.Errorf("task %s not found in queue", taskID)
		}
		if item.Stage != "review" && item.Stage != "qa" {
			return fmt.Errorf("cannot reject task %s in stage '%s'", taskID, item.Stage)
		}
		t := now()
		item.Stage = "coding"
		item.ClaimedBy = ""
		item.Cycles++
		item.UpdatedAt = t
		item.History = append(item.History, HistoryEntry{
			Action: "reject",
			Agent:  agent,
			At:     t,
			Note:   reason,
		})
		result = item
		return nil
	})
	return result, err
}

// Status returns queue info. If taskID is empty, returns full queue with counts.
// If taskID is set, returns that single item (with history).
func Status(taskID string) (interface{}, error) {
	var result interface{}
	err := withLock(func(q *Queue) error {
		if taskID != "" {
			item, exists := q.Items[taskID]
			if !exists {
				return fmt.Errorf("task %s not found in queue", taskID)
			}
			result = item
			return nil
		}
		// Full queue: collect items sorted by submittedAt, compute counts
		counts := map[string]int{
			"coding":      0,
			"review":      0,
			"qa":          0,
			"merge-ready": 0,
		}
		var items []*QueueItem
		for _, item := range q.Items {
			items = append(items, item)
			counts[item.Stage]++
		}
		sort.Slice(items, func(i, j int) bool {
			return items[i].SubmittedAt < items[j].SubmittedAt
		})
		result = StatusResponse{
			Items:  items,
			Counts: counts,
		}
		return nil
	})
	return result, err
}
