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
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup database using root user
docker-compose exec -T sqldb mysqldump -u root -p"$DATABASE_ROOT_PASSWORD" --all-databases > "$BACKUP_DIR/kimai_db_$DATE.sql"
if [ $? -ne 0 ]; then
    echo "Database backup failed."
    exit 1
fi

# Backup important files and directories
docker cp kimai-tracker-kimai:/opt/kimai/.env "$BACKUP_DIR/env_$DATE"
if [ $? -ne 0 ]; then
    echo "Failed to copy .env file."
    exit 1
fi

docker cp kimai-tracker-kimai:/opt/kimai/config/packages/local.yaml "$BACKUP_DIR/local_yaml_$DATE"
if [ $? -ne 0 ]; then
    echo "local.yaml file not found, skipping."
fi

docker cp kimai-tracker-kimai:/opt/kimai/var "$BACKUP_DIR/var_$DATE"
if [ $? -ne 0 ]; then
    echo "Failed to copy var directory."
    exit 1
fi

# Create a tarball of the backups
tar -czf "$BACKUP_DIR/kimai_backup_$DATE.tar.gz" -C "$BACKUP_DIR" \
    "kimai_db_$DATE.sql" "env_$DATE" "local_yaml_$DATE" "var_$DATE"
if [ $? -ne 0 ]; then
    echo "Failed to create tarball."
    exit 1
fi

# Clean up individual files
rm "$BACKUP_DIR/kimai_db_$DATE.sql" "$BACKUP_DIR/env_$DATE"
if [ -f "$BACKUP_DIR/local_yaml_$DATE" ]; then
    rm "$BACKUP_DIR/local_yaml_$DATE"
fi
rm -rf "$BACKUP_DIR/var_$DATE"

echo "Backup completed: kimai_backup_$DATE.tar.gz"

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "kimai_backup_*.tar.gz" -type f -mtime +30 -delete