#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Load environment variables from .env file in the root directory
if [ -f /home/dondoncece/kimai-tracker/.env ]; then
    set -o allexport
    source /home/dondoncece/kimai-tracker/.env
    set +o allexport
else
    echo ".env file not found in the root directory."
    exit 1
fi

BACKUP_DIR="/home/dondoncece/kimai-tracker/backups"

# Check if backup name is provided
if [ $# -eq 0 ]; then
    echo "Please provide the backup name (without extension) as an argument."
    exit 1
fi

BACKUP_NAME=$1

# Check if the backup file exists
if [ ! -f "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" ]; then
    echo "Backup file not found: ${BACKUP_NAME}.tar.gz"
    exit 1
fi

# Extract the date from the backup name
DATE=$(echo $BACKUP_NAME | grep -oP '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}')

if [ -z "$DATE" ]; then
    echo "Could not extract date from backup name. Expected format: kimai_backup_YYYY-MM-DD_HH-MM-SS"
    exit 1
fi

# Create a temporary directory for extraction
TEMP_DIR=$(mktemp -d)

# Extract the backup
tar -xzf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" -C "$TEMP_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to extract the backup file."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Restore database using root user
if [ -f "$TEMP_DIR/kimai_db_$DATE.sql" ]; then
    docker-compose exec -T sqldb mysql -u root -p"$DATABASE_ROOT_PASSWORD" < "$TEMP_DIR/kimai_db_$DATE.sql"
else
    echo "Database backup file not found in the extracted backup."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Restore important files and directories
docker cp "$TEMP_DIR/env_$DATE" kimai-tracker-kimai:/opt/kimai/.env
echo ".env file restored."

if [ -f "$TEMP_DIR/local_yaml_$DATE" ]; then
    docker cp "$TEMP_DIR/local_yaml_$DATE" kimai-tracker-kimai:/opt/kimai/config/packages/local.yaml
    echo "local.yaml file restored."
else
    echo "local.yaml file not found in the backup, skipping."
fi

if [ -d "$TEMP_DIR/var_$DATE" ]; then
    docker cp "$TEMP_DIR/var_$DATE/." kimai-tracker-kimai:/opt/kimai/var/
    echo "var directory restored."
else
    echo "var directory not found in the backup, skipping."
fi

# Clean up extracted files
rm -rf "$TEMP_DIR"

echo "Backup restoration completed."

# Restart the Kimai container to apply changes
docker-compose restart kimai
echo "Kimai container restarted."