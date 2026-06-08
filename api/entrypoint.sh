#!/bin/bash
set -e

echo "[entrypoint.sh] Running database migrations..."
bin/api eval 'Api.Release.migrate'

echo "[entrypoint.sh] Checking if data import is needed..."
if [ -d "/import" ]; then
  ROW_COUNT=$(psql \
    -h "${DB_HOST:-db}" \
    -p "${DB_PORT:-5432}" \
    -U "${DB_USERNAME:-pf_rag_user}" \
    -d "${DB_NAME:-pf_rag_db}" \
    -t \
    -c "SELECT COUNT(*) FROM articles;" 2>/dev/null || echo "0")
  
  ROW_COUNT=$(echo "$ROW_COUNT" | xargs)
  
  if [ "$ROW_COUNT" = "0" ]; then
    echo "[entrypoint.sh] No articles found - importing SQL files from /import..."
    
    for sql_file in /import/*.sql; do
      if [ -f "$sql_file" ]; then
        echo "[entrypoint.sh] Importing: $sql_file"
        psql \
          -h "${DB_HOST:-db}" \
          -p "${DB_PORT:-5432}" \
          -U "${DB_USER:-pf_rag_user}" \
          -d "${DB_NAME:-pf_rag_db}" \
          -f "$sql_file"
        echo "[entrypoint.sh] Completed: $sql_file"
      fi
    done
    
    echo "[entrypoint.sh] All imports completed."
  else
    echo "[entrypoint.sh] Found $ROW_COUNT articles - skipping import"
  fi
else
  echo "[entrypoint.sh] No /import directory found - skipping import"
fi

echo "[entrypoint.sh] Starting application..."
exec bin/api start
