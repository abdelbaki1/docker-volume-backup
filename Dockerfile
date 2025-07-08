# Copyright 2022 - offen.software <hioffen@posteo.de>
# SPDX-License-Identifier: MPL-2.0

FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY . .
RUN go mod download
WORKDIR /app/cmd/backup
RUN go build -o backup .

FROM alpine:3.22

WORKDIR /root
RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
    chmod +x mc && \
    mv mc /usr/local/bin/ && \
    apt-get update && \
    apt-get install -y unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create backup and restore directories
RUN mkdir -p /backup/minio-data /restore
COPY backup.env  /backup.env

COPY --from=builder /app/cmd/backup/backup /usr/bin/backup

# Copy scripts
COPY backup-minio.sh /usr/local/bin/backup-minio.sh
COPY restore-minio.sh /usr/local/bin/restore-minio.sh
RUN apk add --no-cache ca-certificates && \
  chmod a+rw /var/lock
RUN chmod +x /usr/local/bin/backup-minio.sh /usr/local/bin/restore-minio.sh

# Set entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]