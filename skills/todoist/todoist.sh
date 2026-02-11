#!/usr/bin/env bash
set -euo pipefail

# Todoist Task Tracking for OpenClaw
# API Docs: https://developer.todoist.com/rest/v2/

TODOIST_TOKEN="${TODOIST_API_TOKEN:-$(cat ~/.openclaw/credentials/todoist 2>/dev/null || echo '')}"
API_BASE="https://api.todoist.com/rest/v2"

# State labels (using labels since Todoist REST API can't move between sections)
LABEL_QUEUE="state-queue"
LABEL_PROGRESS="state-progress"
LABEL_WAITING="state-waiting"
LABEL_REVIEW="state-review"
LABEL_DONE="state-done"

if [[ -z "$TODOIST_TOKEN" ]]; then
  echo '{"error": "TODOIST_API_TOKEN not set and ~/.openclaw/credentials/todoist not found"}' >&2
  exit 1
fi

# Helper: API call
api() {
  local method="$1"
  local endpoint="$2"
  shift 2
  
  curl -sf -X "$method" \
    -H "Authorization: Bearer $TODOIST_TOKEN" \
    -H "Content-Type: application/json" \
    "$API_BASE$endpoint" \
    "$@"
}

# Get or create project by name
get_or_create_project() {
  local name="$1"
  local projects
  projects=$(api GET "/projects")
  
  local project_id
  project_id=$(echo "$projects" | jq -r ".[] | select(.name == \"$name\") | .id" | head -1)
  
  if [[ -z "$project_id" ]]; then
    local result
    result=$(api POST "/projects" -d "{\"name\": \"$name\"}")
    project_id=$(echo "$result" | jq -r '.id')
  fi
  
  echo "$project_id"
}

# Get or create label
get_or_create_label() {
  local label_name="$1"
  
  local labels
  labels=$(api GET "/labels")
  
  local label_id
  label_id=$(echo "$labels" | jq -r ".[] | select(.name == \"$label_name\") | .id" | head -1)
  
  if [[ -z "$label_id" ]]; then
    local result
    result=$(api POST "/labels" -d "{\"name\": \"$label_name\"}")
    label_id=$(echo "$result" | jq -r '.id')
  fi
  
  echo "$label_name"
}

# Initialize project and state labels
init_project() {
  local project_id
  project_id=$(get_or_create_project "OpenClaw Tasks")
  
  # Ensure state labels exist
  get_or_create_label "$LABEL_QUEUE" >/dev/null
  get_or_create_label "$LABEL_PROGRESS" >/dev/null
  get_or_create_label "$LABEL_WAITING" >/dev/null
  get_or_create_label "$LABEL_REVIEW" >/dev/null
  get_or_create_label "$LABEL_DONE" >/dev/null
  
  echo "$project_id"
}

# Update task state by managing labels
set_task_state() {
  local task_id="$1"
  local new_state_label="$2"
  
  # Get current task
  local task
  task=$(api GET "/tasks/$task_id")
  
  # Get current labels
  local current_labels
  current_labels=$(echo "$task" | jq -r '.labels // []')
  
  # Remove all state labels
  local cleaned_labels
  cleaned_labels=$(echo "$current_labels" | jq '[.[] | select(. | startswith("state-") | not)]')
  
  # Add new state label
  local new_labels
  new_labels=$(echo "$cleaned_labels" | jq --arg label "$new_state_label" '. + [$label]')
  
  # Update task
  api POST "/tasks/$task_id" -d "{\"labels\": $new_labels}"
}

case "${1:-}" in
  create_task)
    PROJECT_ID=$(init_project)
    TITLE="${2:-Untitled task}"
    DESCRIPTION="${3:-}"
    EXTRA_LABELS_JSON="${4:-[]}"  # JSON array of additional label names
    
    # Build payload
    PAYLOAD="{\"content\": \"$TITLE\", \"project_id\": \"$PROJECT_ID\""
    
    if [[ -n "$DESCRIPTION" ]]; then
      PAYLOAD="$PAYLOAD, \"description\": \"$DESCRIPTION\""
    fi
    
    # Build labels array: state-queue + user labels
    LABELS_ARRAY='["'$LABEL_QUEUE'"]'
    
    if [[ "$EXTRA_LABELS_JSON" != "[]" ]]; then
      # Add user labels
      LABELS_ARRAY=$(echo "$EXTRA_LABELS_JSON" | jq --arg queue "$LABEL_QUEUE" '[$queue] + . | unique')
      # Ensure labels exist
      echo "$EXTRA_LABELS_JSON" | jq -r '.[]' | while read -r label; do
        get_or_create_label "$label" >/dev/null
      done
    fi
    
    PAYLOAD="$PAYLOAD, \"labels\": $LABELS_ARRAY"
    PAYLOAD="$PAYLOAD}"
    
    TASK=$(api POST "/tasks" -d "$PAYLOAD")
    TASK_ID=$(echo "$TASK" | jq -r '.id')
    
    # Add creation comment
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"🤖 Task created by OpenClaw\\n📅 $(date '+%Y-%m-%d %H:%M')\\n🟡 State: Queue\\n📝 Ready to start\"}" >/dev/null
    
    echo "$TASK"
    ;;
    
  start_task)
    TASK_ID="$2"
    
    # Set state to progress
    set_task_state "$TASK_ID" "$LABEL_PROGRESS"
    
    # Add start comment
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"🚀 Started working on this\\n⏱️ $(date '+%Y-%m-%d %H:%M')\\n🔵 State: In Progress\"}" >/dev/null
    
    # Return updated task
    api GET "/tasks/$TASK_ID"
    ;;
    
  set_waiting)
    TASK_ID="$2"
    REASON="${3:-Waiting for input}"
    
    # Set state to waiting
    set_task_state "$TASK_ID" "$LABEL_WAITING"
    
    # Add waiting comment
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"⏸️ Set to Waiting\\n📝 Reason: $REASON\\n⏱️ $(date '+%Y-%m-%d %H:%M')\\n🟠 State: Waiting\"}" >/dev/null
    
    api GET "/tasks/$TASK_ID"
    ;;
    
  set_review)
    TASK_ID="$2"
    
    # Set state to review
    set_task_state "$TASK_ID" "$LABEL_REVIEW"
    
    # Add review comment
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"👀 Ready for Review\\n⏱️ $(date '+%Y-%m-%d %H:%M')\\n🟣 State: Review\\nPlease check and provide feedback\"}" >/dev/null
    
    api GET "/tasks/$TASK_ID"
    ;;
    
  complete_task)
    TASK_ID="$2"
    SUMMARY="${3:-Task completed}"
    
    # Set state to done
    set_task_state "$TASK_ID" "$LABEL_DONE"
    
    # Add completion comment
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"✅ Completed\\n📝 $SUMMARY\\n🏁 $(date '+%Y-%m-%d %H:%M')\\n🟢 State: Done\"}" >/dev/null
    
    # Close the task
    api POST "/tasks/$TASK_ID/close"
    
    echo '{"status": "completed", "task_id": "'$TASK_ID'"}'
    ;;
    
  add_comment)
    TASK_ID="$2"
    COMMENT="$3"
    TYPE="${4:-update}"  # update, progress, blocker, decision
    
    # Add emoji prefix based on type
    case "$TYPE" in
      progress) PREFIX="📈 Progress" ;;
      blocker) PREFIX="🚧 Blocker" ;;
      decision) PREFIX="🎯 Decision" ;;
      info) PREFIX="ℹ️ Info" ;;
      *) PREFIX="💬 Update" ;;
    esac
    
    FULL_COMMENT="$PREFIX: $COMMENT\\n⏱️ $(date '+%Y-%m-%d %H:%M')"
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"$FULL_COMMENT\"}"
    ;;
    
  add_label)
    TASK_ID="$2"
    LABEL="$3"
    
    # Ensure label exists
    get_or_create_label "$LABEL" >/dev/null
    
    # Get current task labels
    TASK=$(api GET "/tasks/$TASK_ID")
    CURRENT_LABELS=$(echo "$TASK" | jq -r '.labels // []')
    
    # Add new label (avoiding state labels)
    if [[ "$LABEL" != state-* ]]; then
      NEW_LABELS=$(echo "$CURRENT_LABELS" | jq --arg label "$LABEL" '. + [$label] | unique')
      api POST "/tasks/$TASK_ID" -d "{\"labels\": $NEW_LABELS}"
    else
      echo '{"error": "Cannot manually add state labels"}'
    fi
    ;;
    
  list_by_state)
    PROJECT_ID=$(init_project)
    STATE="${2:-all}"
    
    # Get all tasks from project
    ALL_TASKS=$(api GET "/tasks?project_id=$PROJECT_ID")
    
    case "$STATE" in
      queue) echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_QUEUE'"]))]' ;;
      progress) echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_PROGRESS'"]))]' ;;
      waiting) echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_WAITING'"]))]' ;;
      review) echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_REVIEW'"]))]' ;;
      done) echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_DONE'"]))]' ;;
      active) echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_QUEUE'", "'$LABEL_PROGRESS'", "'$LABEL_WAITING'", "'$LABEL_REVIEW'"]))]' ;;
      *) echo "$ALL_TASKS" ;;
    esac
    ;;
    
  list_all)
    PROJECT_ID=$(init_project)
    api GET "/tasks?project_id=$PROJECT_ID"
    ;;
    
  get_task_details)
    TASK_ID="$2"
    TASK=$(api GET "/tasks/$TASK_ID")
    COMMENTS=$(api GET "/comments?task_id=$TASK_ID")
    
    echo "{\"task\": $TASK, \"comments\": $COMMENTS}"
    ;;
    
  reconcile)
    PROJECT_ID=$(init_project)
    
    # Get all active tasks (not done)
    ALL_TASKS=$(api GET "/tasks?project_id=$PROJECT_ID")
    ACTIVE_TASKS=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_DONE'"]) | not) and .is_completed == false]')
    
    # Get waiting tasks
    WAITING_TASKS=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_WAITING'"]))]')
    
    # Get in-progress tasks for stall check
    PROGRESS_TASKS=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_PROGRESS'"]))]')
    
    # Check for stalled tasks (>24h in progress)
    NOW=$(date +%s)
    STALLED=$(echo "$PROGRESS_TASKS" | jq -r --arg now "$NOW" '[ 
      .[] | 
      select(
        (.created_at | fromdateiso8601) as $created |
        ($now | tonumber) - $created > 86400
      ) |
      {id, content, created_at, labels}
    ]')
    
    # Count by state
    QUEUE_COUNT=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_QUEUE'"]))] | length')
    PROGRESS_COUNT=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_PROGRESS'"]))] | length')
    WAITING_COUNT=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_WAITING'"]))] | length')
    REVIEW_COUNT=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_REVIEW'"]))] | length')
    DONE_COUNT=$(echo "$ALL_TASKS" | jq '[.[] | select(.labels | contains(["'$LABEL_DONE'"]))] | length')
    
    STALLED_COUNT=$(echo "$STALLED" | jq 'length')
    
    # Build status summary
    if [[ "$STALLED_COUNT" -gt 0 ]] || [[ "$WAITING_COUNT" -gt 0 ]]; then
      jq -n \
        --argjson queue "$QUEUE_COUNT" \
        --argjson progress "$PROGRESS_COUNT" \
        --argjson waiting "$WAITING_COUNT" \
        --argjson review "$REVIEW_COUNT" \
        --argjson done "$DONE_COUNT" \
        --argjson stalled "$STALLED_COUNT" \
        --argjson stalled_tasks "$STALLED" \
        --argjson waiting_tasks "$WAITING_TASKS" \
        '{
          status: "alert",
          counts: {
            queue: $queue,
            progress: $progress,
            waiting: $waiting,
            review: $review,
            done: $done
          },
          stalled: $stalled,
          stalled_tasks: $stalled_tasks,
          waiting_tasks: $waiting_tasks
        }'
    else
      jq -n \
        --argjson queue "$QUEUE_COUNT" \
        --argjson progress "$PROGRESS_COUNT" \
        --argjson waiting "$WAITING_COUNT" \
        --argjson review "$REVIEW_COUNT" \
        --argjson done "$DONE_COUNT" \
        '{
          status: "ok",
          counts: {
            queue: $queue,
            progress: $progress,
            waiting: $waiting,
            review: $review,
            done: $done
          },
          stalled: 0
        }'
    fi
    ;;
    
  *)
    echo '{
  "error": "Unknown command",
  "available_commands": [
    "create_task <title> [description] [labels_json]",
    "start_task <task_id>",
    "set_waiting <task_id> [reason]",
    "set_review <task_id>",
    "complete_task <task_id> [summary]",
    "add_comment <task_id> <comment> [type:progress/blocker/decision/info/update]",
    "add_label <task_id> <label>",
    "list_by_state [queue/progress/waiting/review/done/active/all]",
    "list_all",
    "get_task_details <task_id>",
    "reconcile"
  ]
}' >&2
    exit 1
    ;;
esac