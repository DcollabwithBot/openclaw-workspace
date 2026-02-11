#!/usr/bin/env bash
set -euo pipefail

# Todoist Task Tracking for OpenClaw
# API Docs: https://developer.todoist.com/rest/v2/

TODOIST_TOKEN="${TODOIST_API_TOKEN:-$(cat ~/.openclaw/credentials/todoist 2>/dev/null || echo '')}"
API_BASE="https://api.todoist.com/rest/v2"

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
    # Create project
    local result
    result=$(api POST "/projects" -d "{\"name\": \"$name\"}")
    project_id=$(echo "$result" | jq -r '.id')
  fi
  
  echo "$project_id"
}

# Initialize projects if needed
init_projects() {
  get_or_create_project "OpenClaw - Queue" >/dev/null
  get_or_create_project "OpenClaw - Active" >/dev/null
}

case "${1:-}" in
  create_task)
    init_projects
    TITLE="${2:-Untitled task}"
    DESCRIPTION="${3:-}"
    PROJECT="${4:-queue}"
    
    if [[ "$PROJECT" == "queue" ]]; then
      PROJECT_ID=$(get_or_create_project "OpenClaw - Queue")
    elif [[ "$PROJECT" == "active" ]]; then
      PROJECT_ID=$(get_or_create_project "OpenClaw - Active")
    else
      PROJECT_ID="$PROJECT"
    fi
    
    PAYLOAD="{\"content\": \"$TITLE\", \"project_id\": \"$PROJECT_ID\""
    if [[ -n "$DESCRIPTION" ]]; then
      PAYLOAD="$PAYLOAD, \"description\": \"$DESCRIPTION\""
    fi
    PAYLOAD="$PAYLOAD}"
    
    api POST "/tasks" -d "$PAYLOAD"
    ;;
    
  move_to_active)
    init_projects
    TASK_ID="$2"
    PROJECT_ID=$(get_or_create_project "OpenClaw - Active")
    
    api POST "/tasks/$TASK_ID" -d "{\"project_id\": \"$PROJECT_ID\"}"
    ;;
    
  assign_to_user)
    TASK_ID="$2"
    REASON="${3:-Blocked on human input}"
    
    # Get current user ID
    USER_ID=$(api GET "/users" | jq -r '.[0].id // empty')
    
    if [[ -n "$USER_ID" ]]; then
      api POST "/tasks/$TASK_ID" -d "{\"assignee_id\": \"$USER_ID\"}"
    fi
    
    # Add comment with reason
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"⚠️ Blocked: $REASON\"}"
    ;;
    
  complete_task)
    TASK_ID="$2"
    api POST "/tasks/$TASK_ID/close"
    ;;
    
  add_comment)
    TASK_ID="$2"
    COMMENT="$3"
    api POST "/comments" -d "{\"task_id\": \"$TASK_ID\", \"content\": \"$COMMENT\"}"
    ;;
    
  list_active)
    init_projects
    PROJECT_ID=$(get_or_create_project "OpenClaw - Active")
    api GET "/tasks?project_id=$PROJECT_ID"
    ;;
    
  list_assigned)
    # Get current user ID
    USER_ID=$(api GET "/users" | jq -r '.[0].id // empty')
    
    if [[ -z "$USER_ID" ]]; then
      echo "[]"
    else
      api GET "/tasks" | jq "[.[] | select(.assignee_id == \"$USER_ID\")]"
    fi
    ;;
    
  reconcile)
    init_projects
    
    # Get active tasks
    ACTIVE_PROJECT_ID=$(get_or_create_project "OpenClaw - Active")
    ACTIVE_TASKS=$(api GET "/tasks?project_id=$ACTIVE_PROJECT_ID")
    
    # Get assigned tasks
    USER_ID=$(api GET "/users" | jq -r '.[0].id // empty')
    ASSIGNED_TASKS="[]"
    if [[ -n "$USER_ID" ]]; then
      ASSIGNED_TASKS=$(api GET "/tasks" | jq "[.[] | select(.assignee_id == \"$USER_ID\")]")
    fi
    
    # Check for stalled (>24h no updates)
    NOW=$(date +%s)
    STALLED=$(echo "$ACTIVE_TASKS" | jq -r --arg now "$NOW" '[
      .[] | 
      select(
        (now | tonumber) - (.created_at | fromdateiso8601) > 86400
      ) | 
      {id, content, created_at}
    ]')
    
    STALLED_COUNT=$(echo "$STALLED" | jq 'length')
    ASSIGNED_COUNT=$(echo "$ASSIGNED_TASKS" | jq 'length')
    ACTIVE_COUNT=$(echo "$ACTIVE_TASKS" | jq 'length')
    
    if [[ "$STALLED_COUNT" -gt 0 ]] || [[ "$ASSIGNED_COUNT" -gt 0 ]]; then
      echo "{\"status\": \"alert\", \"active\": $ACTIVE_COUNT, \"assigned\": $ASSIGNED_COUNT, \"stalled\": $STALLED_COUNT, \"stalled_tasks\": $STALLED, \"assigned_tasks\": $ASSIGNED_TASKS}"
    else
      echo "{\"status\": \"ok\", \"active\": $ACTIVE_COUNT, \"assigned\": 0, \"stalled\": 0}"
    fi
    ;;
    
  *)
    echo '{"error": "Unknown command. Available: create_task, move_to_active, assign_to_user, complete_task, add_comment, list_active, list_assigned, reconcile"}' >&2
    exit 1
    ;;
esac
