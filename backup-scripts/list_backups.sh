#!/bin/bash

BACKUP_DIR="./backups"

echo "Available backups:"
echo "----------------"
ls -lh "$BACKUP_DIR" | grep 'kimai_backup_' | awk '{print $9, $5, $6, $7, $8}'
