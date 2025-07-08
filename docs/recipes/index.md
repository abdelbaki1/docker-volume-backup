---
title: Recipes
layout: default
nav_order: 4
---

# Recipes
{: .no_toc }

This doc lists configuration for some real-world use cases that you can copy and paste to tweak and match your needs.

1. TOC
{: toc }

## Backing up to AWS S3

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Backing up to Filebase

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_ENDPOINT: s3.filebase.com
      AWS_S3_BUCKET_NAME: filebase-bucket
      AWS_ACCESS_KEY_ID: FILEBASE-ACCESS-KEY
      AWS_SECRET_ACCESS_KEY: FILEBASE-SECRET-KEY
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Backing up to MinIO

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_ENDPOINT: minio.example.com
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: MINIOACCESSKEY
      AWS_SECRET_ACCESS_KEY: MINIOSECRETKEY
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Backing up to MinIO (using Docker secrets)

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_ENDPOINT: minio.example.com
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID_FILE: /run/secrets/minio_access_key
      AWS_SECRET_ACCESS_KEY_FILE: /run/secrets/minio_secret_key
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    secrets:
      - minio_access_key
      - minio_secret_key

volumes:
  data:

secrets:
  minio_access_key:
    # ... define how secret is accessed
  minio_secret_key:
    # ... define how secret is accessed
```

## Using MinIO Client Integration for Backup and Restore

This recipe demonstrates how to use the new MinIO client integration for both backup and restore operations.

### Backup to MinIO using MinIO Client

```yml
version: '3'

services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      OPERATION_MODE: backup
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
      MINIO_BUCKET_NAME: my-backups
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

### Restore from MinIO using MinIO Client

```yml
version: '3'

services:
  restore:
    image: offen/docker-volume-backup:v2
    environment:
      OPERATION_MODE: restore
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
      RESTORE_SOURCE: s3://my-backups/backup-20240326.zip
      RESTORE_DESTINATION: restored-data
    volumes:
      - restored-data:/restore

volumes:
  restored-data:
```

### Complete Example with MinIO Server, Backup, and Restore

```yml
version: '3'

services:
  # MinIO server for object storage
  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"  # API
      - "9001:9001"  # Console
    volumes:
      - minio-data:/data

  # Application that uses a volume
  app:
    image: nginx:alpine
    volumes:
      - app-data:/usr/share/nginx/html
    ports:
      - "8080:80"

  # Backup service
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      OPERATION_MODE: backup
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
      MINIO_BUCKET_NAME: backups
      BACKUP_CRON_EXPRESSION: "0 * * * *"  # Hourly backup
    volumes:
      - app-data:/backup/app-data:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    depends_on:
      - minio

  # Restore service (disabled by default, enable when needed)
  restore:
    image: offen/docker-volume-backup:v2
    profiles: ["restore"]  # Only starts when explicitly requested
    environment:
      OPERATION_MODE: restore
      MINIO_ENDPOINT: http://minio:9000
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
      RESTORE_SOURCE: s3://backups/backup-latest.tar.gz
      RESTORE_DESTINATION: restored-data
    volumes:
      - restored-data:/restore
    depends_on:
      - minio

volumes:
  minio-data:
  app-data:
  restored-data:
```

To run the restore service when needed:

```console
docker-compose --profile restore up restore
```

## Backing up to WebDAV

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      WEBDAV_URL: https://webdav.mydomain.me
      WEBDAV_PATH: /my/directory/
      WEBDAV_USERNAME: user
      WEBDAV_PASSWORD: password
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Backing up to SSH

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      SSH_HOST_NAME: server.local
      SSH_PORT: 2222
      SSH_USER: user
      SSH_REMOTE_PATH: /data
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /path/to/private_key:/root/.ssh/id_rsa

volumes:
  data:
```

## Backing up to Azure Blob Storage

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AZURE_STORAGE_CONTAINER_NAME: backup-container
      AZURE_STORAGE_ACCOUNT_NAME: account-name
      AZURE_STORAGE_PRIMARY_ACCOUNT_KEY: Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Backing up to Dropbox

See [Dropbox Setup](../how-tos/set-up-dropbox.md) on how to get the appropriate environment values.

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      DROPBOX_REFRESH_TOKEN: REFRESH_KEY  # replace
      DROPBOX_APP_KEY: APP_KEY  # replace
      DROPBOX_APP_SECRET: APP_SECRET  # replace
      DROPBOX_REMOTE_PATH: /somedir  # replace
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Backing up locally

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      BACKUP_FILENAME: backup-%Y-%m-%dT%H-%M-%S.tar.gz
      BACKUP_LATEST_SYMLINK: backup-latest.tar.gz
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${HOME}/backups:/archive

volumes:
  data:
```

## Backing up to AWS S3 as well as locally

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${HOME}/backups:/archive

volumes:
  data:
```

## Running on a custom cron schedule

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      # take a backup on every hour
      BACKUP_CRON_EXPRESSION: "0 * * * *"
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Rotating away backups that are older than 7 days

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
      BACKUP_FILENAME: backup-%Y-%m-%dT%H-%M-%S.tar.gz
      BACKUP_PRUNING_PREFIX: backup-
      BACKUP_RETENTION_DAYS: 7
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Encrypting your backups symmetrically using GPG

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
      GPG_PASSPHRASE: somesecretstring
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Encrypting your backups asymmetrically using GPG

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
      GPG_PUBLIC_KEY_RING: | 
        -----BEGIN PGP PUBLIC KEY BLOCK-----

        D/cIHu6GH/0ghlcUVSbgMg5RRI5QKNNKh04uLAPxr75mKwUg0xPUaWgyyrAChVBi
        ...
        -----END PGP PUBLIC KEY BLOCK-----
    volumes:
      - data:/backup/my-app-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Using mariadb-dump/mysqldump to prepare the backup

```yml
services:
  database:
    image: mariadb:latest
    labels:
      - docker-volume-backup.archive-pre=/bin/sh -c 'mariadb-dump -psecret --all-databases > /tmp/dumps/dump.sql'
    volumes:
      - data:/tmp/dumps
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      BACKUP_FILENAME: db.tar.gz
      BACKUP_CRON_EXPRESSION: "0 2 * * *"
    volumes:
      - ./local:/archive
      - data:/backup/data:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data:
```

## Running multiple instances in the same setup

```yml
services:
  # ... define other services using the `data_1` and `data_2` volumes here
  backup_1: &backup_service
    image: offen/docker-volume-backup:v2
    environment: &backup_environment
      BACKUP_CRON_EXPRESSION: "0 2 * * *"
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
      # Label the container using the `data_1` volume as `docker-volume-backup.stop-during-backup=service1`
      BACKUP_STOP_DURING_BACKUP_LABEL: service1
    volumes:
      - data_1:/backup/data-1-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
  backup_2:
    <<: *backup_service
    environment:
      <<: *backup_environment
      # Label the container using the `data_2` volume as `docker-volume-backup.stop-during-backup=service2`
      BACKUP_CRON_EXPRESSION: "0 3 * * *"
      BACKUP_STOP_DURING_BACKUP_LABEL: service2
    volumes:
      - data_2:/backup/data-2-backup:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  data_1:
  data_2:
```

## Running as a non-root user

```yml
services:
  # ... define other services using the `data` volume here
  backup:
    image: offen/docker-volume-backup:v2
    user: 1000:1000
    environment:
      AWS_S3_BUCKET_NAME: backup-bucket
      AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
      AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    volumes:
      - data:/backup/my-app-backup:ro

volumes:
  data:
```
