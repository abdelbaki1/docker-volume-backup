#!/bin/sh
set -e

# Load environment variables
set -o allexport && source /backup.env && set +o allexport

# Check operation mode
if [ "$OPERATION_MODE" = "restore" ]; then
    echo "Running in RESTORE mode"
    exec /usr/local/bin/restore-minio.sh
else
    echo "Running in BACKUP mode (default)"
    exec /usr/local/bin/backup-minio.sh
fi
