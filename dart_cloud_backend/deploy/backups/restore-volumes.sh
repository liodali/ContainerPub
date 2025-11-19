#!/bin/bash

# Docker Volume Restore Script for Dart Cloud Backend
# This script restores Docker volumes from backups

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/data/volumes"

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

Restore Docker volumes from backup files.

OPTIONS:
    -f, --file FILE         Backup file to restore (required)
    -v, --volume VOLUME     Volume to restore (postgres|functions|both) [default: both]
    -y, --yes              Skip confirmation prompt
    -h, --help             Show this help message

EXAMPLES:
    # Restore both volumes from archive
    $0 -f data/volumes/volumes_backup_20240101_120000.tar.gz

    # Restore only PostgreSQL volume
    $0 -f data/volumes/postgres_volume_20240101_120000.tar.gz -v postgres

    # Restore without confirmation
    $0 -f data/volumes/volumes_backup_20240101_120000.tar.gz -y

EOF
    exit 1
}

# Parse command line arguments
BACKUP_FILE=""
VOLUME_TYPE="both"
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            BACKUP_FILE="$2"
            shift 2
            ;;
        -v|--volume)
            VOLUME_TYPE="$2"
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

# Confirmation prompt
if [ "${SKIP_CONFIRM}" = false ]; then
    log_warn "WARNING: This will OVERWRITE existing volume(s)!"
    log_prompt "Backup file: ${BACKUP_FILE}"
    log_prompt "Volume(s): ${VOLUME_TYPE}"
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM
    if [ "${CONFIRM}" != "yes" ]; then
        log_info "Restore cancelled."
        exit 0
    fi
fi

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

log_info "Starting volume restore..."
log_info "Backup file: ${BACKUP_FILE}"

# Extract archive
log_info "Extracting backup archive..."
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Find backup files in extracted directory
POSTGRES_BACKUP=$(find "${TEMP_DIR}" -name "postgres_volume_*.tar.gz" | head -n 1)
FUNCTIONS_BACKUP=$(find "${TEMP_DIR}" -name "functions_volume_*.tar.gz" | head -n 1)

# If single file backup, use it directly
if [ -z "${POSTGRES_BACKUP}" ] && [ -z "${FUNCTIONS_BACKUP}" ]; then
    if [[ "${BACKUP_FILE}" == *"postgres_volume"* ]]; then
        POSTGRES_BACKUP="${BACKUP_FILE}"
    elif [[ "${BACKUP_FILE}" == *"functions_volume"* ]]; then
        FUNCTIONS_BACKUP="${BACKUP_FILE}"
    fi
fi

# Function to restore a volume
restore_volume() {
    local VOLUME_NAME=$1
    local BACKUP_FILE=$2
    
    log_info "Restoring volume: ${VOLUME_NAME}"
    
    # Create volume if it doesn't exist
    if ! docker volume inspect "${VOLUME_NAME}" > /dev/null 2>&1; then
        log_info "Creating volume: ${VOLUME_NAME}"
        docker volume create "${VOLUME_NAME}"
    fi
    
    # Extract backup file if it's compressed
    local EXTRACT_DIR="${TEMP_DIR}/extract_$(basename ${VOLUME_NAME})"
    mkdir -p "${EXTRACT_DIR}"
    
    if [[ "${BACKUP_FILE}" == *.tar.gz ]]; then
        tar -xzf "${BACKUP_FILE}" -C "${EXTRACT_DIR}"
    else
        tar -xf "${BACKUP_FILE}" -C "${EXTRACT_DIR}"
    fi
    
    # Restore volume using a temporary container
    docker run --rm \
        -v "${VOLUME_NAME}:/target" \
        -v "${EXTRACT_DIR}:/source:ro" \
        alpine \
        sh -c "rm -rf /target/* /target/..?* /target/.[!.]* 2>/dev/null || true && cp -a /source/. /target/"
    
    if [ $? -eq 0 ]; then
        log_info "Volume restored successfully: ${VOLUME_NAME}"
        return 0
    else
        log_error "Failed to restore volume: ${VOLUME_NAME}"
        return 1
    fi
}

# Restore PostgreSQL volume
if [ "${VOLUME_TYPE}" = "postgres" ] || [ "${VOLUME_TYPE}" = "both" ]; then
    if [ -n "${POSTGRES_BACKUP}" ] && [ -f "${POSTGRES_BACKUP}" ]; then
        restore_volume "${POSTGRES_VOLUME}" "${POSTGRES_BACKUP}"
        POSTGRES_STATUS=$?
    else
        log_warn "PostgreSQL volume backup not found in archive"
        POSTGRES_STATUS=1
    fi
fi

# Restore functions volume
if [ "${VOLUME_TYPE}" = "functions" ] || [ "${VOLUME_TYPE}" = "both" ]; then
    if [ -n "${FUNCTIONS_BACKUP}" ] && [ -f "${FUNCTIONS_BACKUP}" ]; then
        restore_volume "${FUNCTIONS_VOLUME}" "${FUNCTIONS_BACKUP}"
        FUNCTIONS_STATUS=$?
    else
        log_warn "Functions volume backup not found in archive"
        FUNCTIONS_STATUS=1
    fi
fi

log_info "Volume restore completed!"
log_info "================================================"
log_info "Volume Restore Summary:"
[ ${POSTGRES_STATUS} -eq 0 ] && log_info "  ✓ PostgreSQL volume restored"
[ ${FUNCTIONS_STATUS} -eq 0 ] && log_info "  ✓ Functions volume restored"
log_info "================================================"

exit 0
