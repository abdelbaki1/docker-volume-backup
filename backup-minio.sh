#!/bin/sh
set -o allexport && source /backup.env && set +o allexport

# Configure MinIO client
mc alias set minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

# Create backup directory
BACKUP_DIR="/backup/minio-data"
mkdir -p $BACKUP_DIR

# Mirror MinIO data to backup directory
mc cp -r minio/$MINIO_BUCKET_NAME $BACKUP_DIR/

# Run the backup command
backup
