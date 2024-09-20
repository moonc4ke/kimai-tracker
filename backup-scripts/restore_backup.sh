#!/bin/bash

BACKUP_DIR="/backups"
COMPOSE_PROJECT_NAME="kimai"  # Adjust this to match your docker-compose project name
MYSQL_PASSWORD="password"

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
docker-compose exec -T database mysql -u kimaiuser -p"$MYSQL_PASSWORD" kimai < "$BACKUP_DIR/kimai_db_"*".sql"

# Restore important files and directories
docker cp "$BACKUP_DIR/env_"* ${COMPOSE_PROJECT_NAME}_app_1:/opt/kimai/.env
docker cp "$BACKUP_DIR/local_yaml_"* ${COMPOSE_PROJECT_NAME}_app_1:/opt/kimai/config/packages/local.yaml
docker cp "$BACKUP_DIR/var_"* ${COMPOSE_PROJECT_NAME}_app_1:/opt/kimai/

# Clean up extracted files
rm "$BACKUP_DIR/kimai_db_"*".sql" "$BACKUP_DIR/env_"* "$BACKUP_DIR/local_yaml_"*
rm -rf "$BACKUP_DIR/var_"*

echo "Backup restoration completed."

# Restart the Kimai container to apply changes
docker-compose restart app

echo "Kimai container restarted."