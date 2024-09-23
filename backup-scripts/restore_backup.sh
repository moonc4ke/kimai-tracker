#!/bin/bash

# Load environment variables from .env file in the root directory
if [ -f ../.env ]; then
    source ../.env
fi

BACKUP_DIR="/backups"

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

# Restore database
docker-compose exec -T sqldb mysql -u kimaiuser -p"$MYSQL_PASSWORD" kimai < "$BACKUP_DIR/kimai_db_$DATE.sql"

# Restore important files and directories
docker cp "$BACKUP_DIR/env_$DATE" kimai-tracker-kimai:/opt/kimai/.env
docker cp "$BACKUP_DIR/local_yaml_$DATE" kimai-tracker-kimai:/opt/kimai/config/packages/local.yaml
docker cp "$BACKUP_DIR/var_$DATE" kimai-tracker-kimai:/opt/kimai/

# Clean up extracted files
rm "$BACKUP_DIR/kimai_db_$DATE.sql" "$BACKUP_DIR/env_$DATE" "$BACKUP_DIR/local_yaml_$DATE"
rm -rf "$BACKUP_DIR/var_$DATE"

echo "Backup restoration completed."

# Restart the Kimai container to apply changes
docker-compose restart kimai

echo "Kimai container restarted."