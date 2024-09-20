#!/bin/bash

BACKUP_DIR="/backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
COMPOSE_PROJECT_NAME="kimai"  # Adjust this to match your docker-compose project name
MYSQL_PASSWORD="password"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup database
docker-compose exec -T database mysqldump -u kimaiuser -p"$MYSQL_PASSWORD" kimai > "$BACKUP_DIR/kimai_db_$DATE.sql"

# Backup important files and directories
docker cp ${COMPOSE_PROJECT_NAME}_app_1:/opt/kimai/.env "$BACKUP_DIR/env_$DATE"
docker cp ${COMPOSE_PROJECT_NAME}_app_1:/opt/kimai/config/packages/local.yaml "$BACKUP_DIR/local_yaml_$DATE"
docker cp ${COMPOSE_PROJECT_NAME}_app_1:/opt/kimai/var "$BACKUP_DIR/var_$DATE"

# Create a tarball of the backups
tar -czf "$BACKUP_DIR/kimai_backup_$DATE.tar.gz" -C "$BACKUP_DIR" \
    "kimai_db_$DATE.sql" "env_$DATE" "local_yaml_$DATE" "var_$DATE"

# Clean up individual files
rm "$BACKUP_DIR/kimai_db_$DATE.sql" "$BACKUP_DIR/env_$DATE" "$BACKUP_DIR/local_yaml_$DATE"
rm -rf "$BACKUP_DIR/var_$DATE"

echo "Backup completed: kimai_backup_$DATE.tar.gz"

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "kimai_backup_*.tar.gz" -type f -mtime +30 -delete