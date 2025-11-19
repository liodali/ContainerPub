#!/bin/bash

# Docker Volume Backup Script for Dart Cloud Backend
# This script creates backups of Docker volumes with replication support

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/data/volumes"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=${VOLUME_RETENTION_DAYS:-7}

# Load environment variables
if [ -f "${SCRIPT_DIR}/../.env" ]; then
    source "${SCRIPT_DIR}/../.env"
fi

# Volume configuration
POSTGRES_VOLUME=${POSTGRES_VOLUME:-dart_cloud_backend_postgres_data}
FUNCTIONS_VOLUME=${FUNCTIONS_VOLUME:-dart_cloud_backend_functions_data}
PROJECT_NAME=${COMPOSE_PROJECT_NAME:-dart_cloud_backend}

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

log_info "Starting Docker volume backup..."
log_info "Backup directory: ${BACKUP_DIR}"

# Function to backup a volume
backup_volume() {
    local VOLUME_NAME=$1
    local BACKUP_NAME=$2
    
    log_info "Backing up volume: ${VOLUME_NAME}"
    
    # Check if volume exists
    if ! docker volume inspect "${VOLUME_NAME}" > /dev/null 2>&1; then
        log_warn "Volume '${VOLUME_NAME}' does not exist. Skipping..."
        return 1
    fi
    
    # Create backup using a temporary container
    BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}_${TIMESTAMP}.tar.gz"
    
    docker run --rm \
        -v "${VOLUME_NAME}:/source:ro" \
        -v "${BACKUP_DIR}:/backup" \
        alpine \
        tar -czf "/backup/$(basename ${BACKUP_FILE})" -C /source .
    
    if [ $? -eq 0 ]; then
        BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
        log_info "Volume backup completed: ${BACKUP_FILE} (${BACKUP_SIZE})"
        echo "${BACKUP_FILE}"
        return 0
    else
        log_error "Failed to backup volume: ${VOLUME_NAME}"
        return 1
    fi
}

# Backup PostgreSQL data volume
POSTGRES_BACKUP=$(backup_volume "${POSTGRES_VOLUME}" "postgres_volume")
POSTGRES_STATUS=$?

# Backup functions data volume
FUNCTIONS_BACKUP=$(backup_volume "${FUNCTIONS_VOLUME}" "functions_volume")
FUNCTIONS_STATUS=$?

# Create combined archive
if [ ${POSTGRES_STATUS} -eq 0 ] || [ ${FUNCTIONS_STATUS} -eq 0 ]; then
    log_info "Creating combined volume backup archive..."
    ARCHIVE_FILE="${BACKUP_DIR}/volumes_backup_${TIMESTAMP}.tar"
    
    # Create archive with available backups
    tar -cf "${ARCHIVE_FILE}" -C "${BACKUP_DIR}" \
        $([ ${POSTGRES_STATUS} -eq 0 ] && echo "$(basename ${POSTGRES_BACKUP})") \
        $([ ${FUNCTIONS_STATUS} -eq 0 ] && echo "$(basename ${FUNCTIONS_BACKUP})")
    
    # Compress the archive
    gzip "${ARCHIVE_FILE}"
    ARCHIVE_FILE="${ARCHIVE_FILE}.gz"
    
    if [ $? -eq 0 ]; then
        ARCHIVE_SIZE=$(du -h "${ARCHIVE_FILE}" | cut -f1)
        log_info "Combined volume archive created: ${ARCHIVE_FILE} (${ARCHIVE_SIZE})"
    else
        log_error "Failed to create combined volume archive"
    fi
fi

# Create volume metadata
log_info "Creating volume backup metadata..."
METADATA_FILE="${BACKUP_DIR}/volume_backup_${TIMESTAMP}.meta"
cat > "${METADATA_FILE}" << EOF
Backup Date: $(date)
Timestamp: ${TIMESTAMP}
PostgreSQL Volume: ${POSTGRES_VOLUME}
Functions Volume: ${FUNCTIONS_VOLUME}
PostgreSQL Backup: $([ ${POSTGRES_STATUS} -eq 0 ] && basename ${POSTGRES_BACKUP} || echo "FAILED")
Functions Backup: $([ ${FUNCTIONS_STATUS} -eq 0 ] && basename ${FUNCTIONS_BACKUP} || echo "FAILED")
Archive File: $(basename ${ARCHIVE_FILE})

Volume Information:
$(docker volume inspect "${POSTGRES_VOLUME}" 2>/dev/null || echo "Volume not found")

$(docker volume inspect "${FUNCTIONS_VOLUME}" 2>/dev/null || echo "Volume not found")
EOF

log_info "Metadata saved to: ${METADATA_FILE}"

# Clean up old backups
log_info "Cleaning up volume backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.meta" -type f -mtime +${RETENTION_DAYS} -delete

# Count remaining backups
BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "volumes_backup_*.tar.gz" -type f | wc -l)
log_info "Current volume backup count: ${BACKUP_COUNT}"

log_info "Volume backup process completed!"
log_info "================================================"
log_info "Volume Backup Summary:"
[ ${POSTGRES_STATUS} -eq 0 ] && log_info "  ✓ PostgreSQL: $(basename ${POSTGRES_BACKUP})"
[ ${FUNCTIONS_STATUS} -eq 0 ] && log_info "  ✓ Functions: $(basename ${FUNCTIONS_BACKUP})"
log_info "  - Archive: $(basename ${ARCHIVE_FILE})"
log_info "  - Location: ${BACKUP_DIR}"
log_info "================================================"

exit 0
