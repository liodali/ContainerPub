#!/bin/bash

# Database Restore Script for Dart Cloud Backend
# This script restores PostgreSQL databases from backups

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/data"

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

log_prompt() {
    echo -e "${BLUE}[PROMPT]${NC} $1"
}

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Restore PostgreSQL databases from backup files.

OPTIONS:
    -f, --file FILE         Backup file to restore (required)
    -d, --database DB       Database to restore (main|functions|both) [default: both]
    -y, --yes              Skip confirmation prompt
    -h, --help             Show this help message

EXAMPLES:
    # Restore both databases from archive
    $0 -f data/full_backup_20240101_120000.tar.gz

    # Restore only main database
    $0 -f data/dart_cloud_20240101_120000.sql.gz -d main

    # Restore without confirmation
    $0 -f data/full_backup_20240101_120000.tar.gz -y

EOF
    exit 1
}

# Parse command line arguments
BACKUP_FILE=""
DATABASE_TYPE="both"
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            BACKUP_FILE="$2"
            shift 2
            ;;
        -d|--database)
            DATABASE_TYPE="$2"
            shift 2
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate arguments
if [ -z "${BACKUP_FILE}" ]; then
    log_error "Backup file is required. Use -f or --file option."
    usage
fi

# Check if backup file exists
if [ ! -f "${BACKUP_FILE}" ]; then
    # Try relative to backup directory
    if [ -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
        BACKUP_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
    else
        log_error "Backup file not found: ${BACKUP_FILE}"
        exit 1
    fi
fi

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

# Confirmation prompt
if [ "${SKIP_CONFIRM}" = false ]; then
    log_warn "WARNING: This will OVERWRITE existing database(s)!"
    log_prompt "Backup file: ${BACKUP_FILE}"
    log_prompt "Database(s): ${DATABASE_TYPE}"
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM
    if [ "${CONFIRM}" != "yes" ]; then
        log_info "Restore cancelled."
        exit 0
    fi
fi

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

log_info "Starting database restore..."
log_info "Backup file: ${BACKUP_FILE}"

# Extract archive if it's a tar.gz
if [[ "${BACKUP_FILE}" == *.tar.gz ]]; then
    log_info "Extracting backup archive..."
    tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"
    
    # Find backup files in extracted directory
    MAIN_BACKUP=$(find "${TEMP_DIR}" -name "${POSTGRES_DB}_*.sql.gz" | head -n 1)
    FUNCTION_BACKUP=$(find "${TEMP_DIR}" -name "${FUNCTION_DB}_*.sql.gz" | head -n 1)
else
    # Single file backup
    if [[ "${BACKUP_FILE}" == *"${POSTGRES_DB}"* ]]; then
        MAIN_BACKUP="${BACKUP_FILE}"
    elif [[ "${BACKUP_FILE}" == *"${FUNCTION_DB}"* ]]; then
        FUNCTION_BACKUP="${BACKUP_FILE}"
    else
        log_error "Cannot determine database type from filename"
        exit 1
    fi
fi

# Restore main database
if [ "${DATABASE_TYPE}" = "main" ] || [ "${DATABASE_TYPE}" = "both" ]; then
    if [ -n "${MAIN_BACKUP}" ] && [ -f "${MAIN_BACKUP}" ]; then
        log_info "Restoring main database: ${POSTGRES_DB}"
        
        # Decompress if needed
        if [[ "${MAIN_BACKUP}" == *.gz ]]; then
            gunzip -c "${MAIN_BACKUP}" > "${TEMP_DIR}/main_restore.sql"
            RESTORE_FILE="${TEMP_DIR}/main_restore.sql"
        else
            RESTORE_FILE="${MAIN_BACKUP}"
        fi
        
        # Restore database
        docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
            psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" < "${RESTORE_FILE}"
        
        if [ $? -eq 0 ]; then
            log_info "Main database restored successfully"
        else
            log_error "Failed to restore main database"
            exit 1
        fi
    else
        log_warn "Main database backup not found in archive"
    fi
fi

# Restore functions database
if [ "${DATABASE_TYPE}" = "functions" ] || [ "${DATABASE_TYPE}" = "both" ]; then
    if [ -n "${FUNCTION_BACKUP}" ] && [ -f "${FUNCTION_BACKUP}" ]; then
        log_info "Restoring functions database: ${FUNCTION_DB}"
        
        # Decompress if needed
        if [[ "${FUNCTION_BACKUP}" == *.gz ]]; then
            gunzip -c "${FUNCTION_BACKUP}" > "${TEMP_DIR}/function_restore.sql"
            RESTORE_FILE="${TEMP_DIR}/function_restore.sql"
        else
            RESTORE_FILE="${FUNCTION_BACKUP}"
        fi
        
        # Restore database
        docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER_NAME}" \
            psql -U "${POSTGRES_USER}" -d "${FUNCTION_DB}" < "${RESTORE_FILE}"
        
        if [ $? -eq 0 ]; then
            log_info "Functions database restored successfully"
        else
            log_error "Failed to restore functions database"
            exit 1
        fi
    else
        log_warn "Functions database backup not found in archive"
    fi
fi

log_info "Database restore completed successfully!"
log_info "================================================"

exit 0
