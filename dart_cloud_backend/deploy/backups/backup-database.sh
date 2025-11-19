#!/bin/bash

# Database Backup Script for Dart Cloud Backend
# This script creates backups of PostgreSQL databases with rotation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/data"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

# Load environment variables
if [ -f "${SCRIPT_DIR}/../.env" ]; then
    source "${SCRIPT_DIR}/../.env"
fi

# Database configuration
POSTGRES_USER=${POSTGRES_USER:-dart_cloud}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=${POSTGRES_DB:-dart_cloud}
FUNCTION_DB=${FUNCTION_DB:-functions_db}
POSTGRES_HOST=${POSTGRES_HOST:-postgres}
CONTAINER_NAME=${POSTGRES_CONTAINER:-dart_cloud_postgres}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Check if PostgreSQL password is set
if [ -z "${POSTGRES_PASSWORD}" ]; then
    log_error "POSTGRES_PASSWORD is not set. Please set it in .env file or environment."
    exit 1
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log_error "PostgreSQL container '${CONTAINER_NAME}' is not running."
    exit 1
fi

log_info "Starting database backup..."
log_info "Backup directory: ${BACKUP_DIR}"

# Backup main database
log_info "Backing up main database: ${POSTGRES_DB}"
MAIN_BACKUP_FILE="${BACKUP_DIR}/${POSTGRES_DB}_${TIMESTAMP}.sql"

docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
    pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
    --format=plain \
    --no-owner \
    --no-acl \
    --clean \
    --if-exists \
    > "${MAIN_BACKUP_FILE}"

if [ $? -eq 0 ]; then
    # Compress the backup
    gzip "${MAIN_BACKUP_FILE}"
    MAIN_BACKUP_FILE="${MAIN_BACKUP_FILE}.gz"
    BACKUP_SIZE=$(du -h "${MAIN_BACKUP_FILE}" | cut -f1)
    log_info "Main database backup completed: ${MAIN_BACKUP_FILE} (${BACKUP_SIZE})"
else
    log_error "Failed to backup main database"
    exit 1
fi

# Backup functions database
log_info "Backing up functions database: ${FUNCTION_DB}"
FUNCTION_BACKUP_FILE="${BACKUP_DIR}/${FUNCTION_DB}_${TIMESTAMP}.sql"

docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
    pg_dump -U "${POSTGRES_USER}" -d "${FUNCTION_DB}" \
    --format=plain \
    --no-owner \
    --no-acl \
    --clean \
    --if-exists \
    > "${FUNCTION_BACKUP_FILE}"

if [ $? -eq 0 ]; then
    # Compress the backup
    gzip "${FUNCTION_BACKUP_FILE}"
    FUNCTION_BACKUP_FILE="${FUNCTION_BACKUP_FILE}.gz"
    BACKUP_SIZE=$(du -h "${FUNCTION_BACKUP_FILE}" | cut -f1)
    log_info "Functions database backup completed: ${FUNCTION_BACKUP_FILE} (${BACKUP_SIZE})"
else
    log_error "Failed to backup functions database"
    exit 1
fi

# Create a combined backup archive
log_info "Creating combined backup archive..."
ARCHIVE_FILE="${BACKUP_DIR}/full_backup_${TIMESTAMP}.tar.gz"
tar -czf "${ARCHIVE_FILE}" -C "${BACKUP_DIR}" \
    "$(basename ${MAIN_BACKUP_FILE})" \
    "$(basename ${FUNCTION_BACKUP_FILE})"

if [ $? -eq 0 ]; then
    ARCHIVE_SIZE=$(du -h "${ARCHIVE_FILE}" | cut -f1)
    log_info "Combined backup archive created: ${ARCHIVE_FILE} (${ARCHIVE_SIZE})"
else
    log_error "Failed to create combined backup archive"
fi

# Backup metadata
log_info "Creating backup metadata..."
METADATA_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.meta"
cat > "${METADATA_FILE}" << EOF
Backup Date: $(date)
Timestamp: ${TIMESTAMP}
Main Database: ${POSTGRES_DB}
Functions Database: ${FUNCTION_DB}
PostgreSQL Version: $(docker exec "${CONTAINER_NAME}" psql -U "${POSTGRES_USER}" -t -c "SELECT version();")
Main Backup File: $(basename ${MAIN_BACKUP_FILE})
Function Backup File: $(basename ${FUNCTION_BACKUP_FILE})
Archive File: $(basename ${ARCHIVE_FILE})
EOF

log_info "Metadata saved to: ${METADATA_FILE}"

# Clean up old backups
log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.meta" -type f -mtime +${RETENTION_DAYS} -delete

# Count remaining backups
BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "*.tar.gz" -type f | wc -l)
log_info "Current backup count: ${BACKUP_COUNT}"

log_info "Backup process completed successfully!"
log_info "================================================"
log_info "Backup Summary:"
log_info "  - Main DB: $(basename ${MAIN_BACKUP_FILE})"
log_info "  - Functions DB: $(basename ${FUNCTION_BACKUP_FILE})"
log_info "  - Archive: $(basename ${ARCHIVE_FILE})"
log_info "  - Location: ${BACKUP_DIR}"
log_info "================================================"

exit 0
