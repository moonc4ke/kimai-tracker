#!/bin/bash

# Set the working directory to where the docker-compose.yml file is located
cd /home/dondoncece/kimai-tracker

# Load environment variables from .env file in the root directory
if [ -f .env ]; then
    set -o allexport
    source .env
    set +o allexport
else
    echo ".env file not found in the root directory."
    exit 1
fi

BACKUP_DIR="./backups"
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

# Check if local.yaml exists before trying to copy
if docker exec kimai-tracker-kimai test -f /opt/kimai/config/packages/local.yaml; then
    docker cp kimai-tracker-kimai:/opt/kimai/config/packages/local.yaml "$BACKUP_DIR/local_yaml_$DATE"
    if [ $? -ne 0 ]; then
        echo "Failed to copy local.yaml file."
        exit 1
    fi
    LOCAL_YAML_EXISTS=true
else
    echo "local.yaml file not found, skipping."
    LOCAL_YAML_EXISTS=false
fi

docker cp kimai-tracker-kimai:/opt/kimai/var "$BACKUP_DIR/var_$DATE"
if [ $? -ne 0 ]; then
    echo "Failed to copy var directory."
    exit 1
fi

# Create a tarball of the backups
cd "$BACKUP_DIR"
if [ "$LOCAL_YAML_EXISTS" = true ]; then
    tar -czf "kimai_backup_$DATE.tar.gz" "kimai_db_$DATE.sql" "env_$DATE" "local_yaml_$DATE" "var_$DATE"
else
    tar -czf "kimai_backup_$DATE.tar.gz" "kimai_db_$DATE.sql" "env_$DATE" "var_$DATE"
fi
if [ $? -ne 0 ]; then
    echo "Failed to create tarball."
    exit 1
fi

# Clean up individual files
rm "kimai_db_$DATE.sql" "env_$DATE"
if [ "$LOCAL_YAML_EXISTS" = true ]; then
    rm "local_yaml_$DATE"
fi
rm -rf "var_$DATE"

echo "Backup completed: kimai_backup_$DATE.tar.gz"

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "kimai_backup_*.tar.gz" -type f -mtime +30 -delete