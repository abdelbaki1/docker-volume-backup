#!/bin/sh
set -e
set -o allexport && source /backup.env && set +o allexport

# Configure MinIO client
mc alias set minio $MINIO_ENDPOINT $MINIO_ACCESS_KEY $MINIO_SECRET_KEY

# Configure AWS S3 client if AWS credentials are provided
if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Configuring AWS S3 client"
    mc alias set s3 https://s3.amazonaws.com $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY

    # Use custom endpoint if provided
    if [ -n "$AWS_ENDPOINT" ]; then
        mc alias set s3 $AWS_ENDPOINT $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY
    fi
fi

# Create restore directory
RESTORE_DIR="/restore"
EXTRACT_DIR="$RESTORE_DIR/extracted"
mkdir -p $RESTORE_DIR $EXTRACT_DIR

# Check if RESTORE_SOURCE is provided
if [ -z "$RESTORE_SOURCE" ]; then
    echo "Error: RESTORE_SOURCE environment variable not set. Please specify the path to the backup file."
    exit 1
fi

# Check if RESTORE_DESTINATION is provided
if [ -z "$RESTORE_DESTINATION" ]; then
    # Default to MINIO_BUCKET_NAME if RESTORE_DESTINATION is not specified
    RESTORE_DESTINATION="$MINIO_BUCKET_NAME"
    echo "RESTORE_DESTINATION not specified, using default bucket: $RESTORE_DESTINATION"
fi

echo "Starting restore process from $RESTORE_SOURCE to $RESTORE_DESTINATION"

# Download the backup file from S3 if it starts with s3://
if echo "$RESTORE_SOURCE" | grep -q "^s3://"; then
    S3_PATH=${RESTORE_SOURCE#s3://}
    BUCKET=$(echo $S3_PATH | cut -d'/' -f1)
    KEY=$(echo $S3_PATH | cut -d'/' -f2-)
    echo "Downloading backup file from S3 bucket: $BUCKET, key: $KEY using MinIO client"

    # Use MinIO client to download from S3
    mc cp s3/$BUCKET/$KEY $RESTORE_DIR/backup.zip

    # Check if download was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download file from S3"
        exit 1
    fi

    RESTORE_SOURCE="$RESTORE_DIR/backup.zip"
# Download the backup file if it's a URL
elif echo "$RESTORE_SOURCE" | grep -q "^http"; then
    echo "Downloading backup file from URL: $RESTORE_SOURCE"
    wget -O $RESTORE_DIR/backup.zip "$RESTORE_SOURCE"
    RESTORE_SOURCE="$RESTORE_DIR/backup.zip"
fi

# Extract the backup file
echo "Extracting backup file to $EXTRACT_DIR"
unzip -o "$RESTORE_SOURCE" -d $EXTRACT_DIR

# Ensure the destination bucket exists
echo "Ensuring destination bucket exists: $RESTORE_DESTINATION"
mc mb --ignore-existing minio/$RESTORE_DESTINATION

# Restore the data to MinIO using mirror command
echo "Restoring data to MinIO bucket: $RESTORE_DESTINATION using mirror command"
mc mirror --overwrite $EXTRACT_DIR/ minio/$RESTORE_DESTINATION/

# Check if the restore was successful
if [ $? -eq 0 ]; then
    echo "Restore completed successfully!"
else
    echo "Error: Restore failed!"
    # Clean up before exiting
    rm -rf $RESTORE_DIR/backup.zip $EXTRACT_DIR
    exit 1
fi

# Clean up
echo "Cleaning up temporary files"
rm -rf $RESTORE_DIR/backup.zip $EXTRACT_DIR

echo "Restore process completed"
