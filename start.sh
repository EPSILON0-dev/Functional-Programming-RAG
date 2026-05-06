#!/bin/sh

# Simple startup script. USED FOR DEVELOPMENT PURPOSES ONLY. DO NOT USE IN PRODUCTION ENVIRONMENT.
ui_pid=0
api_pid=0

print_log()
{
    text=$1
    printf "\033[1m[start.sh]\033[0m %s\n" "$text"
}

start_ui()
{
    print_log "Starting UI..."
    cd ui && npm run dev &
    ui_pid=$!
    print_log "UI started with PID $ui_pid, waiting for it to be ready..."
    while ! nc -z localhost 5173; do
        sleep 0.1
    done

    print_log "UI is ready."
}

start_api()
{
    print_log "Starting API..."
    cd api && mix phx.server &
    api_pid=$!
    print_log "API started with PID $api_pid, waiting for it to be ready..."
    while ! nc -z localhost 4000; do
        sleep 0.1
    done

    print_log "API is ready."
}

start_db()
{
    print_log "Starting DB..."
    docker compose -f db/docker-compose.yml up -d
    while ! nc -z localhost 5432; do
        sleep 0.1
    done

    print_log "DB is ready."
}

stop_all()
{
    print_log "Stopping all processes..."
    if [ $ui_pid -ne 0 ]; then
        kill $ui_pid
        print_log "UI process with PID $ui_pid stopped."
    fi
}

main()
{
    trap stop_all EXIT
    start_db
    start_api
    start_ui
}

main
waitpid $ui_pid
waitpid $api_pid
