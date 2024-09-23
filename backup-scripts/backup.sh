#!/bin/bash

# Load environment variables from .env file in the root directory
if [ -f ../.env ]; then
    set -o allexport
    source ../.env
    set -o allexport
else
    echo ".env file not found in the root directory."
    exit 1
fi

BACKUP_DIR="./backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup database
docker-compose exec -T sqldb mysqldump -u kimaiuser -p"$MYSQL_PASSWORD" kimai > "$BACKUP_DIR/kimai_db_$DATE.sql"
if [ $? -ne 0 ]; then
    echo "Database backup failed."
    exit 1
fi

# Backup important files and directories
docker cp kimai-tracker-kimai:/opt/kimai/.env "$BACKUP_DIR/env_$DATE"
docker cp kimai-tracker-kimai:/opt/kimai/config/packages/local.yaml "$BACKUP_DIR/local_yaml_$DATE"
docker cp kimai-tracker-kimai:/opt/kimai/var "$BACKUP_DIR/var_$DATE"

# Create a tarball of the backups
tar -czf "$BACKUP_DIR/kimai_backup_$DATE.tar.gz" -C "$BACKUP_DIR" \
    "kimai_db_$DATE.sql" "env_$DATE" "local_yaml_$DATE" "var_$DATE"

# Clean up individual files
rm "$BACKUP_DIR/kimai_db_$DATE.sql" "$BACKUP_DIR/env_$DATE" "$BACKUP_DIR/local_yaml_$DATE"
rm -rf "$BACKUP_DIR/var_$DATE"

echo "Backup completed: kimai_backup_$DATE.tar.gz"

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "kimai_backup_*.tar.gz" -type f -mtime +30 -delete