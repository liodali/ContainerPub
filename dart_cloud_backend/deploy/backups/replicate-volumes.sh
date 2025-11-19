#!/bin/bash

# Volume Replication Script for Dart Cloud Backend
# This script replicates Docker volumes to a remote location or secondary storage

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/data/volumes"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Load environment variables
if [ -f "${SCRIPT_DIR}/../.env" ]; then
    source "${SCRIPT_DIR}/../.env"
fi

# Replication configuration
REPLICATION_ENABLED=${REPLICATION_ENABLED:-false}
REPLICATION_TYPE=${REPLICATION_TYPE:-local} # local, rsync, s3, or custom
REPLICATION_TARGET=${REPLICATION_TARGET:-}
REPLICATION_INTERVAL=${REPLICATION_INTERVAL:-3600} # seconds

# Volume configuration
POSTGRES_VOLUME=${POSTGRES_VOLUME:-dart_cloud_backend_postgres_data}
FUNCTIONS_VOLUME=${FUNCTIONS_VOLUME:-dart_cloud_backend_functions_data}

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

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Replicate Docker volumes to a remote location or secondary storage.

OPTIONS:
    -t, --type TYPE         Replication type (local|rsync|s3|custom) [default: local]
    -d, --destination DEST  Replication destination path or URL
    -v, --volume VOLUME     Volume to replicate (postgres|functions|both) [default: both]
    -c, --continuous        Run in continuous mode with interval
    -i, --interval SECONDS  Replication interval in seconds [default: 3600]
    -h, --help             Show this help message

EXAMPLES:
    # Replicate to local directory
    $0 -t local -d /mnt/backup

    # Replicate to remote server via rsync
    $0 -t rsync -d user@server:/backup/volumes

    # Replicate to S3 bucket
    $0 -t s3 -d s3://my-bucket/backups/volumes

    # Continuous replication every hour
    $0 -t local -d /mnt/backup -c -i 3600

EOF
    exit 1
}

# Parse command line arguments
VOLUME_TYPE="both"
CONTINUOUS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            REPLICATION_TYPE="$2"
            shift 2
            ;;
        -d|--destination)
            REPLICATION_TARGET="$2"
            shift 2
            ;;
        -v|--volume)
            VOLUME_TYPE="$2"
            shift 2
            ;;
        -c|--continuous)
            CONTINUOUS=true
            shift
            ;;
        -i|--interval)
            REPLICATION_INTERVAL="$2"
            shift 2
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

# Validate replication target
if [ -z "${REPLICATION_TARGET}" ]; then
    log_error "Replication destination is required. Use -d or --destination option."
    usage
fi

log_info "Starting volume replication..."
log_info "Replication type: ${REPLICATION_TYPE}"
log_info "Destination: ${REPLICATION_TARGET}"
log_info "Volume(s): ${VOLUME_TYPE}"

# Function to replicate a volume
replicate_volume() {
    local VOLUME_NAME=$1
    local VOLUME_LABEL=$2
    
    log_info "Replicating volume: ${VOLUME_NAME}"
    
    # Check if volume exists
    if ! docker volume inspect "${VOLUME_NAME}" > /dev/null 2>&1; then
        log_warn "Volume '${VOLUME_NAME}' does not exist. Skipping..."
        return 1
    fi
    
    # Create temporary backup
    TEMP_BACKUP="${BACKUP_DIR}/${VOLUME_LABEL}_replication_${TIMESTAMP}.tar.gz"
    mkdir -p "${BACKUP_DIR}"
    
    docker run --rm \
        -v "${VOLUME_NAME}:/source:ro" \
        -v "${BACKUP_DIR}:/backup" \
        alpine \
        tar -czf "/backup/$(basename ${TEMP_BACKUP})" -C /source .
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create temporary backup for ${VOLUME_NAME}"
        return 1
    fi
    
    # Replicate based on type
    case "${REPLICATION_TYPE}" in
        local)
            log_info "Replicating to local directory: ${REPLICATION_TARGET}"
            mkdir -p "${REPLICATION_TARGET}"
            cp "${TEMP_BACKUP}" "${REPLICATION_TARGET}/"
            REPLICATION_STATUS=$?
            ;;
            
        rsync)
            log_info "Replicating via rsync to: ${REPLICATION_TARGET}"
            rsync -avz --progress "${TEMP_BACKUP}" "${REPLICATION_TARGET}/"
            REPLICATION_STATUS=$?
            ;;
            
        s3)
            log_info "Replicating to S3: ${REPLICATION_TARGET}"
            if command -v aws &> /dev/null; then
                aws s3 cp "${TEMP_BACKUP}" "${REPLICATION_TARGET}/$(basename ${TEMP_BACKUP})"
                REPLICATION_STATUS=$?
            else
                log_error "AWS CLI not found. Please install it to use S3 replication."
                REPLICATION_STATUS=1
            fi
            ;;
            
        custom)
            log_info "Running custom replication command"
            if [ -n "${REPLICATION_COMMAND}" ]; then
                eval "${REPLICATION_COMMAND} ${TEMP_BACKUP} ${REPLICATION_TARGET}"
                REPLICATION_STATUS=$?
            else
                log_error "REPLICATION_COMMAND not set for custom replication"
                REPLICATION_STATUS=1
            fi
            ;;
            
        *)
            log_error "Unknown replication type: ${REPLICATION_TYPE}"
            REPLICATION_STATUS=1
            ;;
    esac
    
    # Clean up temporary backup
    rm -f "${TEMP_BACKUP}"
    
    if [ ${REPLICATION_STATUS} -eq 0 ]; then
        log_info "Volume replicated successfully: ${VOLUME_NAME}"
        return 0
    else
        log_error "Failed to replicate volume: ${VOLUME_NAME}"
        return 1
    fi
}

# Function to perform replication cycle
perform_replication() {
    log_info "================================================"
    log_info "Replication Cycle: $(date)"
    log_info "================================================"
    
    # Replicate PostgreSQL volume
    if [ "${VOLUME_TYPE}" = "postgres" ] || [ "${VOLUME_TYPE}" = "both" ]; then
        replicate_volume "${POSTGRES_VOLUME}" "postgres_volume"
        POSTGRES_STATUS=$?
    fi
    
    # Replicate functions volume
    if [ "${VOLUME_TYPE}" = "functions" ] || [ "${VOLUME_TYPE}" = "both" ]; then
        replicate_volume "${FUNCTIONS_VOLUME}" "functions_volume"
        FUNCTIONS_STATUS=$?
    fi
    
    # Create replication log
    LOG_FILE="${BACKUP_DIR}/replication_${TIMESTAMP}.log"
    cat > "${LOG_FILE}" << EOF
Replication Log
===============
Date: $(date)
Timestamp: ${TIMESTAMP}
Type: ${REPLICATION_TYPE}
Destination: ${REPLICATION_TARGET}

PostgreSQL Volume: $([ ${POSTGRES_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")
Functions Volume: $([ ${FUNCTIONS_STATUS} -eq 0 ] && echo "SUCCESS" || echo "FAILED")
EOF
    
    log_info "Replication cycle completed"
    log_info "Log saved to: ${LOG_FILE}"
}

# Main execution
if [ "${CONTINUOUS}" = true ]; then
    log_info "Starting continuous replication mode"
    log_info "Interval: ${REPLICATION_INTERVAL} seconds"
    log_info "Press Ctrl+C to stop"
    
    while true; do
        perform_replication
        log_info "Waiting ${REPLICATION_INTERVAL} seconds until next replication..."
        sleep ${REPLICATION_INTERVAL}
    done
else
    perform_replication
fi

log_info "Volume replication completed!"

exit 0
