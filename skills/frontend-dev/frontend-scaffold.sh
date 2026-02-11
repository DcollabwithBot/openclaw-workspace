#!/bin/bash
# frontend-scaffold.sh - Next.js/React scaffolding
# Usage: frontend-scaffold.sh <project-name> [nextjs|react]

PROJECT_NAME="${1:-my-app}"
TEMPLATE="${2:-nextjs}"

cd /root/.openclaw/workspace

if [[ "$TEMPLATE" == "nextjs" ]]; then
  echo "Creating Next.js project: $PROJECT_NAME"
  npx create-next-app@latest "$PROJECT_NAME" --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm --yes
elif [[ "$TEMPLATE" == "react" ]]; then
  echo "Creating React + Vite project: $PROJECT_NAME"
  npm create vite@latest "$PROJECT_NAME" -- --template react-ts
  cd "$PROJECT_NAME"
  npm install -D tailwindcss postcss autoprefixer
  npx tailwindcss init -p
else
  echo '{"error": "Template must be nextjs or react"}'
  exit 1
fi

echo "{\"project\": \"$PROJECT_NAME\", \"template\": \"$TEMPLATE\", \"path\": \"/root/.openclaw/workspace/$PROJECT_NAME\"}"