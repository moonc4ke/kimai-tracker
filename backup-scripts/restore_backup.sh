#!/bin/bash

# Load environment variables from .env file in the root directory
if [ -f /home/dondoncece/kimai-tracker/.env ]; then
    set -o allexport
    source /home/dondoncece/kimai-tracker/.env
    set -o allexport
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

# Extract the backup
tar -xzf "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" -C "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to extract the backup file."
    exit 1
fi

# Restore database using root user
docker-compose exec -T sqldb mysql -u root -p"$DATABASE_ROOT_PASSWORD" < "$BACKUP_DIR/kimai_db_$DATE.sql"
if [ $? -ne 0 ]; then
    echo "Database restoration failed."
    exit 1
fi

# Restore important files and directories
docker cp "$BACKUP_DIR/env_$DATE" kimai-tracker-kimai:/opt/kimai/.env
if [ $? -ne 0 ]; then
    echo "Failed to restore .env file."
    exit 1
fi

docker cp "$BACKUP_DIR/local_yaml_$DATE" kimai-tracker-kimai:/opt/kimai/config/packages/local.yaml
if [ $? -ne 0 ]; then
    echo "Failed to restore local.yaml file."
    exit 1
fi

docker cp "$BACKUP_DIR/var_$DATE" kimai-tracker-kimai:/opt/kimai/
if [ $? -ne 0 ]; then
    echo "Failed to restore var directory."
    exit 1
fi

# Clean up extracted files
rm "$BACKUP_DIR/kimai_db_$DATE.sql" "$BACKUP_DIR/env_$DATE" "$BACKUP_DIR/local_yaml_$DATE"
rm -rf "$BACKUP_DIR/var_$DATE"

echo "Backup restoration completed."

# Restart the Kimai container to apply changes
docker-compose restart kimai
if [ $? -ne 0 ]; then
    echo "Failed to restart Kimai container."
    exit 1
fi

echo "Kimai container restarted."