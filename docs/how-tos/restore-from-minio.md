---
title: Restore data from MinIO or S3
layout: default
parent: How Tos
nav_order: 7
---

# Restore data from MinIO or S3

The docker-volume-backup container now supports restoring data directly from MinIO or S3 storage. This feature allows you to restore backups without manually downloading and extracting them.

## Prerequisites

- Access to a MinIO server or S3-compatible storage
- MinIO/S3 credentials (access key and secret key)
- The path to the backup file you want to restore

## Configuring the Restore Operation

To restore data from MinIO or S3, you need to set the `OPERATION_MODE` environment variable to `restore` and provide the necessary MinIO/S3 credentials and paths.

### Required Environment Variables

- `OPERATION_MODE`: Set to `restore` to enable restore mode
- `MINIO_ENDPOINT`: The URL of your MinIO server (e.g., `http://minio:9000`)
- `MINIO_ACCESS_KEY`: Your MinIO access key
- `MINIO_SECRET_KEY`: Your MinIO secret key
- `RESTORE_SOURCE`: Path to the backup file (can be an S3 URL like `s3://bucket-name/backup.zip` or an HTTP URL)

### Optional Environment Variables

- `RESTORE_DESTINATION`: The destination bucket name where data will be restored (defaults to `MINIO_BUCKET_NAME` if not specified)
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: If restoring from AWS S3 (different from your MinIO credentials)
- `AWS_ENDPOINT`: Custom AWS endpoint URL if needed

## Example: Restoring from MinIO

Here's how to restore data from a MinIO backup using Docker:

```console
docker run --rm \
  -v restored-data:/restore \
  --env OPERATION_MODE=restore \
  --env MINIO_ENDPOINT="http://minio:9000" \
  --env MINIO_ACCESS_KEY="minioadmin" \
  --env MINIO_SECRET_KEY="minioadmin" \
  --env RESTORE_SOURCE="s3://my-backups/backup-20240326.zip" \
  --env RESTORE_DESTINATION="restored-data" \
  offen/docker-volume-backup:latest
```

## Example: Restoring from AWS S3

To restore from AWS S3, you need to provide AWS credentials:

```console
docker run --rm \
  -v restored-data:/restore \
  --env OPERATION_MODE=restore \
  --env MINIO_ENDPOINT="http://minio:9000" \
  --env MINIO_ACCESS_KEY="minioadmin" \
  --env MINIO_SECRET_KEY="minioadmin" \
  --env RESTORE_SOURCE="s3://aws-bucket/backup-20240326.zip" \
  --env AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY" \
  --env AWS_SECRET_ACCESS_KEY="AWS_SECRET_KEY" \
  --env RESTORE_DESTINATION="restored-data" \
  offen/docker-volume-backup:latest
```

## Example: Restoring from an HTTP URL

You can also restore from a backup file available via HTTP:

```console
docker run --rm \
  -v restored-data:/restore \
  --env OPERATION_MODE=restore \
  --env MINIO_ENDPOINT="http://minio:9000" \
  --env MINIO_ACCESS_KEY="minioadmin" \
  --env MINIO_SECRET_KEY="minioadmin" \
  --env RESTORE_SOURCE="https://example.com/backups/backup-20240326.zip" \
  --env RESTORE_DESTINATION="restored-data" \
  offen/docker-volume-backup:latest
```

## How the Restore Process Works

1. The container downloads the backup file from the specified source
2. It extracts the backup file to a temporary directory
3. The extracted data is then uploaded to the specified MinIO bucket
4. Temporary files are cleaned up after the restore is complete

This provides a seamless way to restore your data without having to manually handle the backup files.
