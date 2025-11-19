#!/bin/bash

# Complete Backup Script for Dart Cloud Backend
# This script performs a full backup of databases and volumes

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/data"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_section() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Create backup directory
mkdir -p "${BACKUP_DIR}"

log_section "Starting Complete Backup Process"
log_info "Timestamp: ${TIMESTAMP}"
log_info "Backup directory: ${BACKUP_DIR}"

# Backup databases
log_section "Step 1: Database Backup"
if [ -f "${SCRIPT_DIR}/backup-database.sh" ]; then
    bash "${SCRIPT_DIR}/backup-database.sh"
    DB_BACKUP_STATUS=$?
    if [ ${DB_BACKUP_STATUS} -eq 0 ]; then
        log_info "Database backup completed successfully"
    else
        log_error "Database backup failed"
    fi
else
    log_error "Database backup script not found"
    DB_BACKUP_STATUS=1
fi

# Backup volumes
log_section "Step 2: Volume Backup"
if [ -f "${SCRIPT_DIR}/backup-volumes.sh" ]; then
    bash "${SCRIPT_DIR}/backup-volumes.sh"
    VOLUME_BACKUP_STATUS=$?
    if [ ${VOLUME_BACKUP_STATUS} -eq 0 ]; then
        log_info "Volume backup completed successfully"
    else
        log_error "Volume backup failed"
    fi
else
    log_error "Volume backup script not found"
    VOLUME_BACKUP_STATUS=1
fi

# Create complete backup archive
log_section "Step 3: Creating Complete Backup Archive"

if [ ${DB_BACKUP_STATUS} -eq 0 ] || [ ${VOLUME_BACKUP_STATUS} -eq 0 ]; then
    COMPLETE_ARCHIVE="${BACKUP_DIR}/complete_backup_${TIMESTAMP}.tar.gz"
    
    # Find the latest backups
    LATEST_DB_BACKUP=$(find "${BACKUP_DIR}" -name "full_backup_${TIMESTAMP}.tar.gz" -type f 2>/dev/null | head -n 1)
    LATEST_VOLUME_BACKUP=$(find "${BACKUP_DIR}/volumes" -name "volumes_backup_${TIMESTAMP}.tar.gz" -type f 2>/dev/null | head -n 1)
    
    # Create temporary directory for organizing backups
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf ${TEMP_DIR}" EXIT
    
    mkdir -p "${TEMP_DIR}/databases"
    mkdir -p "${TEMP_DIR}/volumes"
    
    # Copy backups to temp directory
    [ -n "${LATEST_DB_BACKUP}" ] && cp "${LATEST_DB_BACKUP}" "${TEMP_DIR}/databases/"
    [ -n "${LATEST_VOLUME_BACKUP}" ] && cp "${LATEST_VOLUME_BACKUP}" "${TEMP_DIR}/volumes/"
    
    # Create complete archive
    tar -czf "${COMPLETE_ARCHIVE}" -C "${TEMP_DIR}" .
    
    if [ $? -eq 0 ]; then
        ARCHIVE_SIZE=$(du -h "${COMPLETE_ARCHIVE}" | cut -f1)
        log_info "Complete backup archive created: ${COMPLETE_ARCHIVE} (${ARCHIVE_SIZE})"
        
        # Create manifest
        MANIFEST_FILE="${BACKUP_DIR}/backup_manifest_${TIMESTAMP}.txt"
        cat > "${MANIFEST_FILE}" << EOF
Complete Backup Manifest
========================
Backup Date: $(date)
Timestamp: ${TIMESTAMP}

Database Backup:
  Status: $([ ${DB_BACKUP_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")
  File: $([ -n "${LATEST_DB_BACKUP}" ] && basename "${LATEST_DB_BACKUP}" || echo "N/A")

Volume Backup:
  Status: $([ ${VOLUME_BACKUP_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")
  File: $([ -n "${LATEST_VOLUME_BACKUP}" ] && basename "${LATEST_VOLUME_BACKUP}" || echo "N/A")

Complete Archive:
  File: $(basename "${COMPLETE_ARCHIVE}")
  Size: ${ARCHIVE_SIZE}
  Location: ${COMPLETE_ARCHIVE}

Backup Contents:
$(tar -tzf "${COMPLETE_ARCHIVE}" | head -n 20)
$([ $(tar -tzf "${COMPLETE_ARCHIVE}" | wc -l) -gt 20 ] && echo "... (truncated)")

Restore Instructions:
=====================
To restore from this backup:

1. Extract the complete archive:
   tar -xzf $(basename "${COMPLETE_ARCHIVE}")

2. Restore databases:
   cd databases && bash ../../restore-database.sh -f full_backup_${TIMESTAMP}.tar.gz

3. Restore volumes:
   cd volumes && bash ../../restore-volumes.sh -f volumes_backup_${TIMESTAMP}.tar.gz

Or use the restore-all.sh script:
   bash restore-all.sh -f $(basename "${COMPLETE_ARCHIVE}")
EOF
        
        log_info "Backup manifest created: ${MANIFEST_FILE}"
    else
        log_error "Failed to create complete backup archive"
    fi
fi

# Summary
log_section "Backup Summary"
echo ""
log_info "Backup Process Completed!"
echo ""
log_info "Status:"
log_info "  Database Backup: $([ ${DB_BACKUP_STATUS} -eq 0 ] && echo '✓ SUCCESS' || echo '✗ FAILED')"
log_info "  Volume Backup:   $([ ${VOLUME_BACKUP_STATUS} -eq 0 ] && echo '✓ SUCCESS' || echo '✗ FAILED')"
echo ""
log_info "Backup Location: ${BACKUP_DIR}"
log_info "Timestamp: ${TIMESTAMP}"
echo ""

if [ ${DB_BACKUP_STATUS} -eq 0 ] && [ ${VOLUME_BACKUP_STATUS} -eq 0 ]; then
    log_info "All backups completed successfully! ✓"
    exit 0
else
    log_warn "Some backups failed. Please check the logs above."
    exit 1
fi
